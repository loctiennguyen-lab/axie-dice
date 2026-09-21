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
import json
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
# .json — Spine's text skeleton
#
# The kit ships MOST Chimeras as binary `.skel` and a couple as `.json` instead. The old
# converter only looked for `.skel`, so those creatures were reported as "missing
# .skel/.atlas/.png" and silently never converted — which read as a broken asset rather than
# as an unread format, and cost the project a boss-grade sprite (`shilin`, a red slime with
# claws and fangs) that was sitting in the kit the whole time.
#
# Same geometry, same atlas, same output — only the container differs, so this produces the
# exact structures parse_skel() does and everything downstream is shared.
# ---------------------------------------------------------------------------

def parse_json_skel(path: pathlib.Path) -> tuple[list[Bone], list[Slot], dict]:
    doc = json.loads(path.read_text(encoding="utf-8"))
    version = str(doc.get("skeleton", {}).get("spine", ""))
    if not version.startswith("3.8"):
        raise ValueError(f"{path.name}: expected Spine 3.8, got {version!r} — this reader "
                         "implements the 3.8 layout only and would mis-parse anything else")

    bones: list[Bone] = []
    by_name: dict[str, Bone] = {}
    for b in doc.get("bones", []):
        # Every field has a default in the JSON form and is simply absent when unset — reading
        # a missing "scaleX" as 0 instead of 1 collapses the whole skeleton to a point.
        bone = Bone(
            name=b["name"],
            parent=by_name.get(b.get("parent")) if b.get("parent") else None,
            rotation=float(b.get("rotation", 0.0)),
            x=float(b.get("x", 0.0)), y=float(b.get("y", 0.0)),
            scale_x=float(b.get("scaleX", 1.0)), scale_y=float(b.get("scaleY", 1.0)),
            shear_x=float(b.get("shearX", 0.0)), shear_y=float(b.get("shearY", 0.0)),
            length=float(b.get("length", 0.0)),
            transform_mode=0,   # only "normal" is honoured; see update_world_transforms()
        )
        bones.append(bone)
        by_name[bone.name] = bone

    slots: list[Slot] = []
    for sl in doc.get("slots", []):
        # A slot with no "attachment" shows nothing in the setup pose. That is not an error:
        # it is how the artist hides a part until an animation reveals it.
        slots.append(Slot(sl["name"], by_name[sl["bone"]], sl.get("attachment")))
    slot_index = {sl.name: i for i, sl in enumerate(slots)}

    raw_skins = doc.get("skins", [])
    skins = (raw_skins if isinstance(raw_skins, list)
             else [{"name": k, "attachments": v} for k, v in raw_skins.items()])

    attachments: dict = {}
    for skin in skins:
        for slot_name, by_att in (skin.get("attachments") or {}).items():
            idx = slot_index.get(slot_name)
            if idx is None:
                continue
            for att_name, a in by_att.items():
                att = _json_attachment(att_name, a)
                if att is not None:
                    attachments[(idx, att_name)] = att
    return bones, slots, attachments, {}   # JSON path carries no animations — see parse_skel


def _json_attachment(att_name: str, a: dict):
    att_type = a.get("type", "region")
    # `path` is the ATLAS region name and defaults to the attachment's own name. Everything
    # else that carries no pixels (boundingbox, path, point, clipping) is skipped — unlike the
    # binary reader, there is no stream to keep in sync, so skipping is free.
    if att_type == "region":
        return RegionAttachment(
            name=att_name, path=a.get("path", att_name),
            rotation=float(a.get("rotation", 0.0)),
            x=float(a.get("x", 0.0)), y=float(a.get("y", 0.0)),
            scale_x=float(a.get("scaleX", 1.0)), scale_y=float(a.get("scaleY", 1.0)),
            width=float(a.get("width", 0.0)), height=float(a.get("height", 0.0)))

    if att_type == "mesh":
        flat_uvs = a.get("uvs", [])
        uvs = [(flat_uvs[i], flat_uvs[i + 1]) for i in range(0, len(flat_uvs), 2)]
        raw = a.get("vertices", [])
        # Spine packs weighted and unweighted meshes into the same "vertices" array and gives
        # no flag: a plain mesh has exactly 2 numbers per vertex, a weighted one is a run of
        # (boneCount, [bone, x, y, weight] * boneCount) per vertex. Length is the only tell.
        if len(raw) == len(uvs) * 2:
            verts = [(raw[i], raw[i + 1]) for i in range(0, len(raw), 2)]
            weighted = False
        else:
            verts, weighted, i = [], True, 0
            for _ in range(len(uvs)):
                count = int(raw[i]); i += 1
                influences = []
                for _ in range(count):
                    influences.append((int(raw[i]), raw[i + 1], raw[i + 2], raw[i + 3]))
                    i += 4
                verts.append(influences)
        return MeshAttachment(name=att_name, path=a.get("path", att_name), uvs=uvs,
                              triangles=a.get("triangles", []), vertices=verts,
                              weighted=weighted)
    return None


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

    # Everything below is walked purely to reach the ANIMATIONS block, which is the last
    # thing in the file. Nothing here is kept except the animations themselves and the one
    # bit of event data the animation reader needs (see read_events).
    for _ in range(r.varint()):               # additional skins
        r.string_ref()                        # name
        for _ in range(r.varint()):           # bones
            r.varint()
        for _ in range(r.varint()):           # ik constraints
            r.varint()
        for _ in range(r.varint()):           # transform constraints
            r.varint()
        for _ in range(r.varint()):           # path constraints
            r.varint()
        for _ in range(r.varint()):
            r.varint()                        # slot index
            for _ in range(r.varint()):
                read_attachment(r, r.string_ref(), nonessential)

    event_has_audio = read_events(r)
    animations = read_animations(r, event_has_audio)

    # THE SELF-CHECK THAT MAKES THIS SAFE. Every block above is walked byte by byte, and a
    # single miscounted field silently desynchronises everything after it — the failure mode
    # is not an exception, it is plausible-looking garbage. The animation block is the last
    # thing in a .skel, so landing exactly on EOF is a strong end-to-end proof that the whole
    # walk was right. Without it, a wrong pose would be indistinguishable from a wrong parse.
    if r.i != len(r.d):
        raise ValueError(
            f"{path.name}: parser finished at byte {r.i} of {len(r.d)} "
            f"({len(r.d) - r.i} left over) — the skeleton walk desynchronised somewhere; "
            "the animations read out of it cannot be trusted")
    return bones, slots, attachments, animations


# ---------------------------------------------------------------------------
# Animations (Spine 3.8 binary) — enough of them to evaluate ONE pose
# ---------------------------------------------------------------------------
#
# WHY THIS EXISTS. The setup pose is the rigger's neutral layout, not the pose the creature
# is meant to be seen in. For most of the kit the two coincide, but for several they do not:
# dryad-ranger's canopy lies on its side, aqua-alpha-wolf's parts sit apart, dryad-mage is in
# a T-pose, aqua-slime-sup's lily pad floats above its head. What puts those right is the
# first frame of the idle animation, which lives in a section this reader used to stop short
# of.
#
# ONLY FRAME 0 IS KEPT. Every timeline is walked in full — it has to be, or the stream
# desynchronises — but only the value at the first keyframe is retained. That is all a static
# sprite needs, and it keeps this from turning into a runtime.
#
# WHAT IS APPLIED vs MERELY WALKED. Applied: bone rotate/translate/scale/shear and slot
# attachment changes. Walked and discarded: colours, deform, draw order, events, and the IK /
# transform / path constraint timelines. Constraints would need a solver, and a solver is the
# line between "reads a pose" and "is a runtime" — see apply_animation_pose() for what that
# costs on the three skeletons where it shows.

CURVE_STEPPED = 1
CURVE_BEZIER = 2


def read_curve(r: BinaryReader) -> None:
    """Consume a frame's interpolation record. Linear (0) carries no payload."""
    t = r.byte()
    if t == CURVE_BEZIER:
        r.float(); r.float(); r.float(); r.float()


def read_events(r: BinaryReader) -> list:
    """Event definitions. Returns, per event, whether it carries an audio path — the
    animation reader needs exactly that one bit, because an event frame for an event WITH
    audio is two floats longer than one without."""
    out = []
    for _ in range(r.varint()):
        r.string_ref()                        # name
        r.varint(False)                       # intValue (signed)
        r.float()                             # floatValue
        r.string()                            # stringValue
        audio = r.string()                    # audioPath
        if audio is not None:
            r.float(); r.float()              # volume, balance
        out.append(audio is not None)
    return out


def read_animations(r: BinaryReader, event_has_audio: list) -> dict:
    """{animation name: {"bones": {index: {...}}, "slots": {index: attachment_name}}},
    every value taken from the timeline's FIRST keyframe."""
    anims = {}
    for _ in range(r.varint()):
        name = r.string()
        anims[name] = _read_animation(r, event_has_audio)
    return anims


def _read_animation(r: BinaryReader, event_has_audio: list) -> dict:
    bone_pose: dict = {}
    slot_pose: dict = {}
    deform_pose: dict = {}

    for _ in range(r.varint()):               # slot timelines
        slot_index = r.varint()
        for _ in range(r.varint()):
            ttype = r.byte()
            frames = r.varint()
            if ttype == 0:                    # attachment
                for f in range(frames):
                    r.float()
                    att = r.string_ref()
                    if f == 0:
                        slot_pose[slot_index] = att
            elif ttype == 1:                  # colour
                for f in range(frames):
                    r.float(); r.int32()
                    if f < frames - 1:
                        read_curve(r)
            elif ttype == 2:                  # two-colour
                for f in range(frames):
                    r.float(); r.int32(); r.int32()
                    if f < frames - 1:
                        read_curve(r)
            else:
                raise ValueError(f"unknown slot timeline type {ttype}")

    for _ in range(r.varint()):               # bone timelines
        bone_index = r.varint()
        entry = bone_pose.setdefault(bone_index, {})
        for _ in range(r.varint()):
            ttype = r.byte()
            frames = r.varint()
            if ttype == 0:                    # rotate
                for f in range(frames):
                    r.float()
                    deg = r.float()
                    if f == 0:
                        entry["rotate"] = deg
                    if f < frames - 1:
                        read_curve(r)
            elif ttype in (1, 2, 3):          # translate, scale, shear
                key = {1: "translate", 2: "scale", 3: "shear"}[ttype]
                for f in range(frames):
                    r.float()
                    x, y = r.float(), r.float()
                    if f == 0:
                        entry[key] = (x, y)
                    if f < frames - 1:
                        read_curve(r)
            else:
                raise ValueError(f"unknown bone timeline type {ttype}")

    for _ in range(r.varint()):               # IK constraint timelines
        r.varint()
        frames = r.varint()
        for f in range(frames):
            r.float(); r.float(); r.float()   # time, mix, softness
            r.sbyte(); r.bool(); r.bool()     # bendDirection, compress, stretch
            if f < frames - 1:
                read_curve(r)

    for _ in range(r.varint()):               # transform constraint timelines
        r.varint()
        frames = r.varint()
        for f in range(frames):
            for _ in range(5):                # time + 4 mixes
                r.float()
            if f < frames - 1:
                read_curve(r)

    for _ in range(r.varint()):               # path constraint timelines
        r.varint()
        for _ in range(r.varint()):
            ttype = r.byte()
            frames = r.varint()
            floats = 3 if ttype == 2 else 2   # PATH_MIX carries two mixes, the rest one value
            for f in range(frames):
                for _ in range(floats):
                    r.float()
                if f < frames - 1:
                    read_curve(r)

    # Deform. KEPT, not discarded: a mesh whose bones move while its vertices stay on the
    # setup shape comes out smeared, which looks like bad art rather than a missing feature.
    # aqua-slime-atk is the clearest case in this kit.
    for _ in range(r.varint()):               # per skin
        skin_index = r.varint()
        for _ in range(r.varint()):
            slot_index = r.varint()
            for _ in range(r.varint()):
                att_name = r.string_ref()
                frames = r.varint()
                for f in range(frames):
                    r.float()                 # time
                    end = r.varint()
                    values = None
                    start = 0
                    if end != 0:
                        start = r.varint()
                        values = [r.float() for _ in range(end)]
                    if f == 0 and skin_index == 0:
                        # `end == 0` is Spine's "no change from setup" encoding, which is a
                        # real instruction: it clears any deform rather than leaving one on.
                        deform_pose[(slot_index, att_name)] = (start, values)
                    if f < frames - 1:
                        read_curve(r)

    for _ in range(r.varint()):               # draw order timelines
        r.float()
        for _ in range(r.varint()):
            r.varint(); r.varint()

    for _ in range(r.varint()):               # event timelines
        r.float()                             # time
        idx = r.varint()
        r.varint(False)                       # intValue
        r.float()                             # floatValue
        if r.bool():                          # stringValue overridden?
            r.string()
        if idx < len(event_has_audio) and event_has_audio[idx]:
            r.float(); r.float()              # volume, balance

    return {"bones": bone_pose, "slots": slot_pose, "deform": deform_pose}


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
# Posing
# ---------------------------------------------------------------------------

## DEFAULT: the setup pose, i.e. posing OFF. Pass --pose action/idle/normal to turn it on.
##
## It defaults off because posing was MEASURED and did not earn its place. The theory was
## that the handful of chimeras that composite badly (aqua-alpha-wolf's parts sit apart,
## dryad-mage is splayed, dryad-ranger's canopy lies over, aqua-slime-sup's lily pad floats
## clear of its head) were showing the rigger's neutral layout, and that the first frame of
## the idle clip would put them right. It does not: rendered side by side at 230px, the
## posed and unposed versions of all eight suspects are near-identical, because these rigs'
## idle clips START at the setup pose. Turning it on by default would rewrite twenty PNGs
## for no visible gain, so it is opt-in.
##
## The follow-up theory, that IK / transform constraints were doing the missing work, was
## measured too and also fails: aqua-slime-sup and aqua-slime-boss composite badly with ZERO
## constraints of any kind, while aqua-wolf (4 IK, 13 transform), werewolf (8, 11) and
## daddy-bear (5, 20, 1 path) all composite fine. So the gap between this compositor and the
## kit's own rendered portraits is NOT explained yet, and nobody should assume a constraint
## solver would close it.
##
## What the reader below IS good for: it is the parsing half of any future frame-sequence
## export, and it is verified — the walk lands exactly on EOF for all 20 binaries, and the
## animation counts it recovers match the kit's own CHIMERA_NOTES.md table one for one.
DEFAULT_POSE = ""


def pick_pose(animations: dict, wanted: str) -> str:
    """The animation to pose from, or "" to keep the setup pose. Falls back from the exact
    name to any idle clip, so a skeleton that spells it differently still gets posed rather
    than silently dropping back to the rigger's layout."""
    if not animations or not wanted:
        return ""
    if wanted in animations:
        return wanted
    for candidate in sorted(animations):
        if "idle" in candidate and "normal" in candidate:
            return candidate
    for candidate in sorted(animations):
        if "idle" in candidate:
            return candidate
    return ""


def apply_animation_pose(bones: list, slots: list, anim: dict) -> int:
    """Move the skeleton onto an animation's FIRST keyframe, in place.

    The value conventions are Spine's own, and they are not uniform — getting one wrong
    bends a limb instead of failing:
        rotate    ADDS to the setup rotation
        translate ADDS to the setup x/y
        scale     MULTIPLIES the setup scale
        shear     ADDS to the setup shear
    A slot timeline sets the visible attachment outright, and `None` means "show nothing" —
    that is how the rigger hides a part the idle pose does not use, and honouring it is what
    removes dryad-ranger's stray sleep glyph.

    Returns how many bones were touched, so the caller can report a pose that did nothing.
    """
    touched = 0
    for index, vals in anim.get("bones", {}).items():
        if index >= len(bones):
            continue
        b = bones[index]
        if "rotate" in vals:
            b.rotation += vals["rotate"]
        if "translate" in vals:
            b.x += vals["translate"][0]
            b.y += vals["translate"][1]
        if "scale" in vals:
            b.scale_x *= vals["scale"][0]
            b.scale_y *= vals["scale"][1]
        if "shear" in vals:
            b.shear_x += vals["shear"][0]
            b.shear_y += vals["shear"][1]
        touched += 1
    for index, att_name in anim.get("slots", {}).items():
        if index < len(slots):
            slots[index].attachment_name = att_name
    return touched


def apply_deform(attachments: dict, anim: dict) -> int:
    """Overwrite each deformed mesh's vertices with the animation's first keyframe.

    Spine stores a deform frame as a SPARSE run: `start` is where the run begins in the
    flattened float array and the values follow, everything outside the run staying at its
    setup value. For an unweighted mesh those floats ARE the local positions; for a weighted
    one they are offsets added to each influence's bone-space position. Both are handled,
    because this kit uses both.

    Returns how many attachments were deformed.
    """
    done = 0
    for (slot_index, att_name), (start, values) in anim.get("deform", {}).items():
        att = attachments.get((slot_index, att_name))
        if att is None or not isinstance(att, MeshAttachment):
            continue
        if values is None:
            continue                          # "no change from setup" — nothing to write
        if not att.weighted:
            flat = [c for xy in att.vertices for c in xy]
            for i, v in enumerate(values):
                if start + i < len(flat):
                    flat[start + i] = v
            att.vertices = [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]
        else:
            # The flattened deform array has two floats per INFLUENCE, in the same order the
            # influences were read.
            i = 0
            new_verts = []
            for influences in att.vertices:
                out = []
                for bone_index, vx, vy, weight in influences:
                    dx = values[i - start] if start <= i < start + len(values) else 0.0
                    dy = values[i + 1 - start] if start <= i + 1 < start + len(values) else 0.0
                    out.append((bone_index, vx + dx, vy + dy, weight))
                    i += 2
                new_verts.append(out)
            att.vertices = new_verts
        done += 1
    return done


# ---------------------------------------------------------------------------
# World transforms
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


def convert(skel_dir: pathlib.Path, out_dir: pathlib.Path, scale: float = 1.0,
            pose: str = DEFAULT_POSE) -> dict:
    name = skel_dir.name
    skel = skel_dir / f"{name}.skel"
    skel_json = skel_dir / f"{name}.json"
    atlas = skel_dir / f"{name}.atlas"
    page_path = skel_dir / f"{name}.png"
    if not (atlas.exists() and page_path.exists()) or not (skel.exists() or skel_json.exists()):
        return {"name": name, "ok": False, "why": "missing .skel/.json, .atlas or .png"}

    if skel.exists():
        bones, slots, attachments, animations = parse_skel(skel)
    else:
        bones, slots, attachments, animations = parse_json_skel(skel_json)
    regions = parse_atlas(atlas)
    page = Image.open(page_path).convert("RGBA")

    # Pose BEFORE the world transforms — apply_animation_pose() edits the local setup values
    # that update_world_transforms() then composes.
    used_pose = pick_pose(animations, pose)
    posed_bones = 0
    deformed = 0
    if used_pose:
        posed_bones = apply_animation_pose(bones, slots, animations[used_pose])
        deformed = apply_deform(attachments, animations[used_pose])
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
            "meshes": mesh_count, "bones": len(bones), "path": str(out_path),
            "pose": used_pose or "(setup)", "posed_bones": posed_bones,
            "deformed": deformed}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chimeras_dir")
    ap.add_argument("out_dir")
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--only", default="", help="comma-separated skeleton names")
    ap.add_argument("--pose", default=DEFAULT_POSE,
                    help="animation whose FIRST frame to pose from; '' keeps the setup pose")
    args = ap.parse_args()

    src = pathlib.Path(args.chimeras_dir)
    out = pathlib.Path(args.out_dir)
    wanted = {s for s in args.only.split(",") if s}

    ok = fail = 0
    for d in sorted(p for p in src.iterdir() if p.is_dir()):
        if wanted and d.name not in wanted:
            continue
        try:
            res = convert(d, out, args.scale, args.pose)
        except Exception as exc:                       # noqa: BLE001 - report, keep going
            res = {"name": d.name, "ok": False, "why": f"{type(exc).__name__}: {exc}"}
        if res["ok"]:
            ok += 1
            print(f"  OK    {res['name']:24s} {res['size'][0]:4d}x{res['size'][1]:<4d} "
                  f"{res['slots']:2d} slots ({res['meshes']:2d} mesh), {res['bones']:2d} bones, "
                  f"pose {res['pose']} ({res['posed_bones']} bones, "
                  f"{res['deformed']} deforms)")
        else:
            fail += 1
            print(f"  FAIL  {res['name']:24s} {res['why']}")
    print(f"\n{ok} converted, {fail} failed")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
