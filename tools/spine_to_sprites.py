#!/usr/bin/env python3
"""Convert Spine 3.8 skeletons from the Axie Origins Kit into flat PNG sprites for Godot.

WHY THIS EXISTS
---------------
The Origins Kit ships its Chimeras as Spine assets (`<name>.skel` binary + `<name>.atlas`
+ `<name>.png` atlas page). Godot cannot read those without the `spine-godot` runtime, which
is a separate plugin under Esoteric Software's own licence. This project deliberately does
not take that dependency (see production/session-state/godot-port-active.md).

What makes a runtime unnecessary here is that a static SETUP POSE is enough for the
battlefield: the port animates monsters by moving and scaling the whole sprite, not by
deforming it. So this reads the binary skeleton, computes the setup-pose world transform of
every bone, and composites each slot's attachment — taken out of the atlas page — onto one
canvas in draw order. The result is an ordinary PNG that Godot imports like any other texture.

A CORRECTION WORTH KEEPING: an earlier version of this file asserted that every attachment
in the set was a plain `region`, "verified" against the two skeletons that ship as readable
JSON (machito, shilin). Those two happen to be the simplest in the kit. Sixteen of the
twenty binaries use MESH attachments, many of them bone-weighted, so both are implemented
below. The lesson is the general one: two convenient samples are not a survey.

This is a lossy conversion ON PURPOSE: animation, slot colours and alternate skins are
discarded. It converts art, not behaviour.

FORMAT REFERENCE
----------------
Spine 3.8 binary layout, mirroring spine-runtimes' SkeletonBinary. The header was verified
by hand against slime.skel before any of this was written:
    1c <27 bytes>  hash "9MSlgEpsENNj0OfwMdKoCpW4Yho"
    07 <6 bytes>   version "3.8.99"
    c3b18000       x       -355.0
    c2900000       y        -72.0
    44318000       width    710.0
    43ed480c       height   474.56
    01             nonessential
    42700000       fps       60.0
    0a "./images/" imagesPath
Byte sequences like `c3 b1` look like UTF-8 and are not — they are plain big-endian floats.
Do not "fix" the file encoding.

Usage:
    python3 tools/spine_to_sprites.py <chimeras-dir> <out-dir> [--scale 1.0] [--only name,...]
"""

from __future__ import annotations

import argparse
import math
import pathlib
import struct
import sys

from PIL import Image, ImageChops, ImageDraw

# Spine 3.8 AttachmentType enum order.
ATTACHMENT_TYPES = ["region", "boundingbox", "mesh", "linkedmesh", "path", "point", "clipping"]


class BinaryReader:
    """Big-endian reader with Spine's varint and length-prefixed string conventions."""

    def __init__(self, data: bytes):
        self.d = data
        self.i = 0
        # Spine 3.8 stores a string table right after the header and then refers to entries
        # by 1-based index everywhere a name can repeat (slot attachments, skin entries,
        # attachment names and paths). Reading those as inline strings instead desynchronises
        # the whole stream a few bytes in — which looks like a corrupt file rather than a
        # wrong reader, so it is worth being explicit about.
        self.strings: list = []

    def byte(self) -> int:
        v = self.d[self.i]
        self.i += 1
        return v

    def sbyte(self) -> int:
        v = self.byte()
        return v - 256 if v > 127 else v

    def bool(self) -> bool:
        return self.byte() != 0

    def float(self) -> float:
        v = struct.unpack_from(">f", self.d, self.i)[0]
        self.i += 4
        return v

    def int32(self) -> int:
        v = struct.unpack_from(">i", self.d, self.i)[0]
        self.i += 4
        return v

    def varint(self, optimize_positive: bool = True) -> int:
        """Spine's 7-bit varint. `optimize_positive=False` zig-zags the sign."""
        b = self.byte()
        result = b & 0x7F
        if b & 0x80:
            b = self.byte()
            result |= (b & 0x7F) << 7
            if b & 0x80:
                b = self.byte()
                result |= (b & 0x7F) << 14
                if b & 0x80:
                    b = self.byte()
                    result |= (b & 0x7F) << 21
                    if b & 0x80:
                        b = self.byte()
                        result |= (b & 0x7F) << 28
        return result if optimize_positive else ((result >> 1) ^ -(result & 1))

    def string_ref(self):
        """Resolve a 1-based index into the string table; index 0 means null."""
        idx = self.varint()
        return None if idx == 0 else self.strings[idx - 1]

    def string(self):
        """None for a null string, "" for an empty one, else UTF-8 of (n-1) bytes."""
        n = self.varint()
        if n == 0:
            return None
        if n == 1:
            return ""
        n -= 1
        s = self.d[self.i:self.i + n].decode("utf-8", errors="replace")
        self.i += n
        return s


class Bone:
    __slots__ = ("name", "parent", "rotation", "x", "y", "scale_x", "scale_y",
                 "shear_x", "shear_y", "length", "transform_mode",
                 "a", "b", "c", "d", "wx", "wy")

    def __init__(self, **kw):
        for k, v in kw.items():
            setattr(self, k, v)
        self.a = self.b = self.c = self.d = 0.0
        self.wx = self.wy = 0.0


class Slot:
    __slots__ = ("name", "bone", "attachment_name")

    def __init__(self, name, bone, attachment_name):
        self.name = name
        self.bone = bone
        self.attachment_name = attachment_name


class RegionAttachment:
    __slots__ = ("name", "path", "rotation", "x", "y", "scale_x", "scale_y", "width", "height")

    def __init__(self, **kw):
        for k, v in kw.items():
            setattr(self, k, v)


class MeshAttachment:
    """A textured triangle mesh. `vertices` is either plain (x, y) pairs in the slot bone's
    local space, or — when `weighted` — a per-vertex list of (bone, x, y, weight) influences
    that must be summed in world space."""

    __slots__ = ("name", "path", "uvs", "triangles", "vertices", "weighted")

    def __init__(self, **kw):
        for k, v in kw.items():
            setattr(self, k, v)


# ---------------------------------------------------------------------------
# .atlas — Spine's text atlas
# ---------------------------------------------------------------------------

def parse_atlas(path: pathlib.Path) -> dict:
    """{region_name: {xy, size, orig, offset, rotate}} for the single page these files use."""
    regions: dict[str, dict] = {}
    lines = path.read_text().splitlines()
    i = 0
    while i < len(lines) and not lines[i].strip():
        i += 1
    i += 1                                   # page image filename
    while i < len(lines) and ":" in lines[i]:  # page header (size/format/filter/repeat)
        i += 1
    current = None
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if not line.startswith(" ") and not line.startswith("\t"):
            current = line.strip()
            regions[current] = {"rotate": False, "offset": (0, 0)}
        else:
            key, _, val = line.strip().partition(":")
            val = val.strip()
            if key == "rotate":
                regions[current]["rotate"] = val == "true"
            elif key in ("xy", "size", "orig", "offset"):
                regions[current][key] = tuple(int(x) for x in val.split(","))
        i += 1
    return regions


# ---------------------------------------------------------------------------
# .skel — Spine 3.8 binary
# ---------------------------------------------------------------------------

def parse_skel(path: pathlib.Path) -> tuple[list[Bone], list[Slot], dict]:
    r = BinaryReader(path.read_bytes())
    r.string()                                # hash
    version = r.string()
    if not (version or "").startswith("3.8"):
        raise ValueError(f"{path.name}: expected Spine 3.8, got {version!r} — this reader "
                         "implements the 3.8 layout only and would mis-parse anything else")
    r.float(); r.float(); r.float(); r.float()   # x, y, width, height
    nonessential = r.bool()
    if nonessential:
        r.float()                             # fps
        r.string()                            # imagesPath
        r.string()                            # audioPath

    r.strings = [r.string() for _ in range(r.varint())]

    bones: list[Bone] = []
    for i in range(r.varint()):
        name = r.string()
        parent = None if i == 0 else bones[r.varint()]
        bones.append(Bone(
            name=name, parent=parent,
            rotation=r.float(), x=r.float(), y=r.float(),
            scale_x=r.float(), scale_y=r.float(),
            shear_x=r.float(), shear_y=r.float(),
            length=r.float(), transform_mode=r.varint(),
        ))
        r.bool()                              # skinRequired
        if nonessential:
            r.int32()                         # colour

    slots: list[Slot] = []
    for _ in range(r.varint()):
        name = r.string()
        bone = bones[r.varint()]
        r.int32()                             # colour
        if r.int32() != -1:                   # darkColour, 0xffffffff == none
            pass
        slots.append(Slot(name, bone, r.string_ref()))
        r.varint()                            # blendMode

    for _ in range(r.varint()):               # IK constraints
        r.string(); r.varint(); r.bool()
        for _ in range(r.varint()):
            r.varint()
        r.varint(); r.float(); r.float(); r.sbyte()
        r.bool(); r.bool(); r.bool()

    for _ in range(r.varint()):               # transform constraints
        r.string(); r.varint(); r.bool()
        for _ in range(r.varint()):
            r.varint()
        r.varint(); r.bool(); r.bool()
        for _ in range(10):
            r.float()

    for _ in range(r.varint()):               # path constraints
        r.string(); r.varint(); r.bool()
        for _ in range(r.varint()):
            r.varint()
        r.varint(); r.varint(); r.varint(); r.varint()
        for _ in range(5):
            r.float()

    # Default skin only. Alternate skins are read past but their attachments are ignored:
    # the port picks one look per monster, and honouring skins would need a selection rule
    # that does not exist anywhere in the game data.
    attachments: dict[tuple[int, str], RegionAttachment] = {}
    slot_count = r.varint()
    for _ in range(slot_count):
        slot_index = r.varint()
        for _ in range(r.varint()):
            att_name = r.string_ref()
            att = read_attachment(r, att_name, nonessential)
            if att is not None:
                attachments[(slot_index, att_name)] = att
    return bones, slots, attachments


def read_vertices(r: BinaryReader, vertex_count: int):
    """Spine's shared vertex block: plain positions, or per-vertex bone weights."""
    if not r.bool():
        return [(r.float(), r.float()) for _ in range(vertex_count)], False
    verts = []
    for _ in range(vertex_count):
        # The per-vertex influence count is a VARINT in 3.8. Older runtimes (3.6/3.7) stored
        # it as a float, and following those docs desynchronises the stream on the very first
        # weighted vertex — which then consumes the rest of the file and surfaces as a buffer
        # overrun at EOF rather than as an error here. Confirmed against the raw bytes of
        # treant.skel: `01 0a <3 floats>` per vertex, i.e. count=1, bone=10, x, y, weight.
        influences = r.varint()
        verts.append([(r.varint(), r.float(), r.float(), r.float()) for _ in range(influences)])
    return verts, True


def read_short_array(r: BinaryReader):
    return [(r.byte() << 8) | r.byte() for _ in range(r.varint())]


def read_attachment(r: BinaryReader, att_name: str, nonessential: bool):
    name = r.string_ref() or att_name
    att_type = ATTACHMENT_TYPES[r.byte()]

    if att_type == "region":
        path = r.string_ref() or name
        rotation = r.float()
        x, y = r.float(), r.float()
        scale_x, scale_y = r.float(), r.float()
        width, height = r.float(), r.float()
        r.int32()                             # colour
        return RegionAttachment(name=name, path=path, rotation=rotation, x=x, y=y,
                                scale_x=scale_x, scale_y=scale_y, width=width, height=height)

    if att_type == "mesh":
        path = r.string_ref() or name
        r.int32()                             # colour
        vertex_count = r.varint()
        uvs = [(r.float(), r.float()) for _ in range(vertex_count)]
        triangles = read_short_array(r)
        vertices, weighted = read_vertices(r, vertex_count)
        r.varint()                            # hullLength
        if nonessential:
            read_short_array(r)               # edges
            r.float(); r.float()              # width, height
        return MeshAttachment(name=name, path=path, uvs=uvs, triangles=triangles,
                              vertices=vertices, weighted=weighted)

    # The remaining types carry no pixels, but their bytes still have to be consumed or the
    # stream desynchronises for everything after them.
    if att_type == "boundingbox":
        read_vertices(r, r.varint())
        if nonessential:
            r.int32()                         # colour
        return None

    if att_type == "path":
        r.bool(); r.bool()                    # closed, constantSpeed
        vertex_count = r.varint()
        read_vertices(r, vertex_count)
        for _ in range(vertex_count // 3):    # segment lengths
            r.float()
        if nonessential:
            r.int32()
        return None

    if att_type == "point":
        r.float(); r.float(); r.float()       # rotation, x, y
        if nonessential:
            r.int32()
        return None

    if att_type == "clipping":
        r.varint()                            # endSlotIndex
        read_vertices(r, r.varint())
        if nonessential:
            r.int32()
        return None

    if att_type == "linkedmesh":
        # Deforms another mesh's geometry. Not resolved here — the parent mesh is already
        # drawn, and a linked copy in the setup pose would double it up.
        r.string_ref()                        # path
        r.int32()                             # colour
        r.string_ref()                        # skin
        r.string_ref()                        # parent
        r.bool()                              # inheritDeform
        if nonessential:
            r.float(); r.float()              # width, height
        return None

    raise ValueError(f"unhandled attachment type '{att_type}' for '{name}'")


# ---------------------------------------------------------------------------
# Setup-pose world transforms
# ---------------------------------------------------------------------------

def update_world_transforms(bones: list[Bone]) -> None:
    """Setup pose only: no animation, no IK, no constraints.

    Bones arrive parents-first in the file, so a single forward pass suffices. Only
    transformMode 0 (normal) is honoured — the modes that ignore parent rotation/scale would
    need the inherit flags, and nothing in this asset set uses them.
    """
    for b in bones:
        rot_y = b.rotation + 90 + b.shear_y
        la = math.cos(math.radians(b.rotation + b.shear_x)) * b.scale_x
        lb = math.cos(math.radians(rot_y)) * b.scale_y
        lc = math.sin(math.radians(b.rotation + b.shear_x)) * b.scale_x
        ld = math.sin(math.radians(rot_y)) * b.scale_y
        if b.parent is None:
            b.a, b.b, b.c, b.d = la, lb, lc, ld
            b.wx, b.wy = b.x, b.y
        else:
            p = b.parent
            b.wx = p.a * b.x + p.b * b.y + p.wx
            b.wy = p.c * b.x + p.d * b.y + p.wy
            b.a = p.a * la + p.b * lc
            b.b = p.a * lb + p.b * ld
            b.c = p.c * la + p.d * lc
            b.d = p.c * lb + p.d * ld


def region_world_corners(att: RegionAttachment, bone: Bone, region: dict):
    """The attachment's 4 corners in world space, as (TL, TR, BR, BL) in Spine's Y-up space.

    Mirrors RegionAttachment.updateOffset(): the region's trimmed offset inside its original
    frame has to be folded in, otherwise every trimmed sprite lands a few pixels off.
    """
    ow, oh = region.get("orig", region["size"])
    # `size` is the region's LOGICAL (unrotated) width and height. `rotate: true` only says
    # the packer stored it turned 90 degrees inside the page — it does not change the logical
    # size. Swapping here stretched every rotated part along the wrong axis (slime's eyes came
    # out 406px tall instead of 46), which reads as bad art rather than as a transform bug.
    rw, rh = region["size"]
    ox, oy = region.get("offset", (0, 0))

    region_scale_x = att.width / max(ow, 1) * att.scale_x
    region_scale_y = att.height / max(oh, 1) * att.scale_y
    local_x = -att.width / 2 * att.scale_x + ox * region_scale_x
    local_y = -att.height / 2 * att.scale_y + oy * region_scale_y
    local_x2 = local_x + rw * region_scale_x
    local_y2 = local_y + rh * region_scale_y

    rad = math.radians(att.rotation)
    cos, sin = math.cos(rad), math.sin(rad)
    pts = []
    for lx, ly in ((local_x, local_y2), (local_x2, local_y2), (local_x2, local_y), (local_x, local_y)):
        ax = lx * cos - ly * sin + att.x
        ay = lx * sin + ly * cos + att.y
        pts.append((ax * bone.a + ay * bone.b + bone.wx,
                    ax * bone.c + ay * bone.d + bone.wy))
    return pts


# ---------------------------------------------------------------------------
# Compositing
# ---------------------------------------------------------------------------

def untrimmed_region_image(page: Image.Image, region: dict) -> Image.Image:
    """The region restored to its ORIGINAL, untrimmed frame.

    Spine's packer crops transparent borders and records what it removed as `offset` (from
    the bottom-left) against `orig`. Mesh UVs address the untrimmed frame, so rebuilding it
    is what lets a mesh be sampled with a plain u*w / v*h lookup instead of reimplementing
    MeshAttachment.updateUVs()'s four rotation cases.
    """
    sub = region_image(page, region)
    ow, oh = region.get("orig", region["size"])
    ox, oy = region.get("offset", (0, 0))
    if (sub.width, sub.height) == (ow, oh) and (ox, oy) == (0, 0):
        return sub
    full = Image.new("RGBA", (max(ow, 1), max(oh, 1)), (0, 0, 0, 0))
    full.alpha_composite(sub, (ox, oh - oy - sub.height))
    return full


def draw_triangle(canvas: Image.Image, src: Image.Image, src_tri, dst_tri) -> None:
    """Affine-map one UV triangle of `src` onto `dst_tri` in `canvas`.

    Per-triangle rather than per-quad because a mesh's triangles do not share a single
    affine transform — that is the entire point of a mesh. Each is rendered into a small
    tile the size of its own bounding box, so cost tracks triangle area rather than canvas
    area (whole-canvas warps per triangle made a 20-skeleton run unusably slow).
    """
    xs = [p[0] for p in dst_tri]
    ys = [p[1] for p in dst_tri]
    x0, y0 = int(math.floor(min(xs))) - 1, int(math.floor(min(ys))) - 1
    x1, y1 = int(math.ceil(max(xs))) + 1, int(math.ceil(max(ys))) + 1
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(canvas.width, x1), min(canvas.height, y1)
    if x1 <= x0 or y1 <= y0:
        return

    # Solve the affine that maps tile-local destination coords back to source pixels.
    (sx0, sy0), (sx1, sy1), (sx2, sy2) = src_tri
    (dx0, dy0), (dx1, dy1), (dx2, dy2) = [(p[0] - x0, p[1] - y0) for p in dst_tri]
    det = (dx1 - dx0) * (dy2 - dy0) - (dx2 - dx0) * (dy1 - dy0)
    if abs(det) < 1e-9:
        return
    a = ((sx1 - sx0) * (dy2 - dy0) - (sx2 - sx0) * (dy1 - dy0)) / det
    b = ((sx2 - sx0) * (dx1 - dx0) - (sx1 - sx0) * (dx2 - dx0)) / det
    c = sx0 - a * dx0 - b * dy0
    d = ((sy1 - sy0) * (dy2 - dy0) - (sy2 - sy0) * (dy1 - dy0)) / det
    e = ((sy2 - sy0) * (dx1 - dx0) - (sy1 - sy0) * (dx2 - dx0)) / det
    f = sy0 - d * dx0 - e * dy0

    tile = src.transform((x1 - x0, y1 - y0), Image.AFFINE, (a, b, c, d, e, f),
                         resample=Image.BILINEAR)
    mask = Image.new("L", (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(mask).polygon([(dx0, dy0), (dx1, dy1), (dx2, dy2)], fill=255)
    tile.putalpha(ImageChops.multiply(tile.getchannel("A"), mask))
    canvas.alpha_composite(tile, (x0, y0))


def mesh_world_vertices(att, bone: Bone, bones: list) -> list:
    """Setup-pose world positions for every vertex of a mesh."""
    if not att.weighted:
        return [(x * bone.a + y * bone.b + bone.wx,
                 x * bone.c + y * bone.d + bone.wy) for x, y in att.vertices]
    out = []
    for influences in att.vertices:
        wx = wy = 0.0
        for bone_index, vx, vy, weight in influences:
            b = bones[bone_index]
            wx += (vx * b.a + vy * b.b + b.wx) * weight
            wy += (vx * b.c + vy * b.d + b.wy) * weight
        out.append((wx, wy))
    return out


def region_image(page: Image.Image, region: dict) -> Image.Image:
    x, y = region["xy"]
    w, h = region["size"]
    if region["rotate"]:
        # A rotated region is stored 90 deg CW in the page; un-rotate to upright.
        sub = page.crop((x, y, x + h, y + w)).rotate(-90, expand=True)
    else:
        sub = page.crop((x, y, x + w, y + h))
    return sub.convert("RGBA")


def paste_quad(canvas: Image.Image, src: Image.Image, quad, to_canvas) -> None:
    """Affine-paste `src` so its corners land on `quad` (TL, TR, BR, BL), Y flipped."""
    tl, tr, br, bl = (to_canvas(p) for p in quad)
    w, h = src.size
    # PIL's AFFINE maps OUTPUT -> INPUT, so solve for the inverse directly.
    dx1, dy1 = tr[0] - tl[0], tr[1] - tl[1]
    dx2, dy2 = bl[0] - tl[0], bl[1] - tl[1]
    det = dx1 * dy2 - dx2 * dy1
    if abs(det) < 1e-6:
        return
    a = w * dy2 / det
    b = -w * dx2 / det
    c = -(a * tl[0] + b * tl[1])
    d = -h * dy1 / det
    e = h * dx1 / det
    f = -(d * tl[0] + e * tl[1])
    warped = src.transform(canvas.size, Image.AFFINE, (a, b, c, d, e, f),
                           resample=Image.BICUBIC)
    canvas.alpha_composite(warped)


## Slots that exist only to carry combat VFX. They are attached in the setup pose, so a
## naive composite draws a creature wearing its own impact effects — the stray rings and
## sparks visible in the first conversion pass. Matched on the slot name because that is the
## only signal the format gives: `fx`, `fxa3`, `boby-fx` and so on.
_EFFECT_SLOT_PARTS = ("fx", "vfx", "glow", "trail", "spark", "impact")


def is_effect_slot(slot_name: str) -> bool:
    name = (slot_name or "").lower()
    return any(part in name.split("-") or name.startswith(part) or name.endswith(part)
               for part in _EFFECT_SLOT_PARTS)


def convert(skel_dir: pathlib.Path, out_dir: pathlib.Path, scale: float = 1.0) -> dict:
    name = skel_dir.name
    skel = skel_dir / f"{name}.skel"
    atlas = skel_dir / f"{name}.atlas"
    page_path = skel_dir / f"{name}.png"
    if not (skel.exists() and atlas.exists() and page_path.exists()):
        return {"name": name, "ok": False, "why": "missing .skel/.atlas/.png"}

    bones, slots, attachments = parse_skel(skel)
    regions = parse_atlas(atlas)
    page = Image.open(page_path).convert("RGBA")
    update_world_transforms(bones)

    drawn = []
    for slot_index, slot in enumerate(slots):
        if not slot.attachment_name:
            continue
        if is_effect_slot(slot.name):
            continue
        att = attachments.get((slot_index, slot.attachment_name))
        if att is None:
            continue
        region = regions.get(att.path)
        if region is None:
            continue
        drawn.append((att, slot.bone, region))

    if not drawn:
        return {"name": name, "ok": False, "why": "no drawable slots in the setup pose"}

    # Resolve every attachment to world-space geometry FIRST, so the canvas can be sized to
    # the creature's real extent. Sizing from the skeleton's declared width/height instead
    # clips any part posed outside it, which several of these skeletons do.
    geometry = []
    for att, bone, region in drawn:
        if isinstance(att, MeshAttachment):
            geometry.append(("mesh", att, region, mesh_world_vertices(att, bone, bones)))
        else:
            geometry.append(("region", att, region, region_world_corners(att, bone, region)))

    pts = [p for _kind, _a, _r, verts in geometry for p in verts]
    min_x, max_x = min(p[0] for p in pts), max(p[0] for p in pts)
    min_y, max_y = min(p[1] for p in pts), max(p[1] for p in pts)
    pad = 4
    cw = max(1, int(math.ceil((max_x - min_x) * scale)) + pad * 2)
    ch = max(1, int(math.ceil((max_y - min_y) * scale)) + pad * 2)
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))

    # Spine is Y-up, images are Y-down.
    def to_canvas(p):
        return ((p[0] - min_x) * scale + pad, (max_y - p[1]) * scale + pad)

    mesh_count = 0
    for kind, att, region, verts in geometry:
        if kind == "region":
            paste_quad(canvas, region_image(page, region), verts, to_canvas)
            continue
        mesh_count += 1
        src = untrimmed_region_image(page, region)
        sw, sh = src.size
        dst = [to_canvas(v) for v in verts]
        tris = att.triangles
        for t in range(0, len(tris) - 2, 3):
            i0, i1, i2 = tris[t], tris[t + 1], tris[t + 2]
            src_tri = [(att.uvs[i][0] * sw, att.uvs[i][1] * sh) for i in (i0, i1, i2)]
            draw_triangle(canvas, src, src_tri, [dst[i0], dst[i1], dst[i2]])

    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{name}.png"
    canvas.save(out_path)
    return {"name": name, "ok": True, "size": canvas.size, "slots": len(drawn),
            "meshes": mesh_count, "bones": len(bones), "path": str(out_path)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chimeras_dir")
    ap.add_argument("out_dir")
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--only", default="", help="comma-separated skeleton names")
    args = ap.parse_args()

    src = pathlib.Path(args.chimeras_dir)
    out = pathlib.Path(args.out_dir)
    wanted = {s for s in args.only.split(",") if s}

    ok = fail = 0
    for d in sorted(p for p in src.iterdir() if p.is_dir()):
        if wanted and d.name not in wanted:
            continue
        try:
            res = convert(d, out, args.scale)
        except Exception as exc:                       # noqa: BLE001 - report, keep going
            res = {"name": d.name, "ok": False, "why": f"{type(exc).__name__}: {exc}"}
        if res["ok"]:
            ok += 1
            print(f"  OK    {res['name']:24s} {res['size'][0]:4d}x{res['size'][1]:<4d} "
                  f"{res['slots']:2d} slots ({res['meshes']:2d} mesh), {res['bones']:2d} bones")
        else:
            fail += 1
            print(f"  FAIL  {res['name']:24s} {res['why']}")
    print(f"\n{ok} converted, {fail} failed")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
