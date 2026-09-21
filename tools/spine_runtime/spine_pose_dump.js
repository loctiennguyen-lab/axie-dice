#!/usr/bin/env node
// Dump a Spine 3.8 skeleton's WORLD-SPACE geometry using Esoteric's own 3.8 runtime.
//
// WHY THIS EXISTS, AND WHY IT IS NOT tools/spine_to_sprites.py
// ------------------------------------------------------------
// spine_to_sprites.py reimplements the pose maths in Python. It is faithful about bones,
// meshes and the atlas, and it still gets several of these creatures visibly wrong —
// dryad-ranger comes out lying on its side rather than standing. Two theories for that
// were measured and both failed (see DEFAULT_POSE's comment in that file), so rather than
// keep guessing, this hands the maths to the runtime that defines the answer.
//
// spine-ts 3.8 loads the kit's binaries directly — the kit is Spine 3.8.99 and a 4.x
// runtime cannot read it, which is also why spine-godot is not an option without
// re-exporting every skeleton from a licensed Spine editor. The 3.8 runtime has no such
// problem: it resolves bones, IK / transform / path constraints, the animation stack,
// atlas rotation and trimming, and emits UVs in page space. This script then prints that
// geometry as JSON and stops. Rasterising is spine_pose_render.py's job, and it is dumb by
// design: textured triangles against the atlas page, nothing to get wrong.
//
// Usage: node spine_pose_dump.js <core.js> <skel-dir> <name> [animation] [fps] [maxFrames]
// With no animation it emits the setup pose; the animation, when given, is applied at t=0.
const fs = require('fs');
const vm = require('vm');

const sandbox = { console, Math, Date, Object, Array, Uint8Array, Float32Array, Int32Array,
                  Uint16Array, ArrayBuffer, DataView, String, Number, Boolean, JSON, isNaN,
                  parseFloat, parseInt, Error, TypeError, RangeError, Map, Set };
sandbox.window = sandbox; sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), sandbox);
const spine = sandbox.spine;
if (!spine) { console.error('spine namespace not found'); process.exit(1); }

const dir = process.argv[3], name = process.argv[4];
const animName = process.argv[5] || '';

// A texture stub. Nothing is rasterised here — only the atlas page's declared size matters,
// and that comes from the .atlas text, not the image.
// The stub MUST report the page's real pixel size. TextureAtlasPage.setTexture() overwrites
// page.width/height from the texture image and then derives every region's UVs as x/width —
// so a 1x1 stub silently yields UVs in PIXELS instead of 0..1, and every triangle samples
// far outside the page. Caught by rendering an empty image, not by any error.
const atlasText = fs.readFileSync(`${dir}/${name}.atlas`, 'utf8');
const pageSizes = [];
for (const line of atlasText.split(/\r?\n/)) {
  const m = line.match(/^\s*size:\s*(\d+)\s*,\s*(\d+)\s*$/);
  if (m) pageSizes.push({ width: parseInt(m[1], 10), height: parseInt(m[2], 10) });
}
let pageIndex = 0;
class FakeTexture extends spine.Texture {
  constructor(size) { super(size); }
  setFilters() {} setWraps() {} dispose() {}
}
const atlas = new spine.TextureAtlas(atlasText,
  () => new FakeTexture(pageSizes[Math.min(pageIndex++, pageSizes.length - 1)] || { width: 1, height: 1 }));

const loader = new spine.AtlasAttachmentLoader(atlas);
const binary = new spine.SkeletonBinary(loader);
const data = binary.readSkeletonData(new Uint8Array(fs.readFileSync(`${dir}/${name}.skel`)));

const fps = parseFloat(process.argv[6] || '0');
const maxFrames = parseInt(process.argv[7] || '0', 10);
const skeleton = new spine.Skeleton(data);
const anim = animName ? data.findAnimation(animName) : null;
if (animName && !anim) { console.error(`no animation '${animName}' in ${name}`); process.exit(2); }

function snapshot() {
  const slots = [];
  for (const slot of skeleton.drawOrder) {
    const att = slot.getAttachment();
    if (!att) continue;
    if (att instanceof spine.RegionAttachment) {
      const v = new Float32Array(8);
      att.computeWorldVertices(slot.bone, v, 0, 2);
      slots.push({ slot: slot.data.name, type: 'region', region: att.region.name,
                   verts: Array.from(v), uvs: Array.from(att.uvs) });
    } else if (att instanceof spine.MeshAttachment) {
      const n = att.worldVerticesLength;
      const v = new Float32Array(n);
      att.computeWorldVertices(slot, 0, n, v, 0, 2);
      slots.push({ slot: slot.data.name, type: 'mesh', region: att.region.name,
                   verts: Array.from(v), uvs: Array.from(att.uvs),
                   triangles: Array.from(att.triangles) });
    }
  }
  return slots;
}

function poseAt(t) {
  skeleton.setToSetupPose();
  if (anim) {
    // MixBlend.setup onto the fresh setup pose above makes this an ABSOLUTE sample at t,
    // independent of whatever was posed before it — so one frame's rounding cannot
    // accumulate into the next the way stepping an AnimationState forward would.
    anim.apply(skeleton, 0, t, false, [], 1, spine.MixBlend.setup, spine.MixDirection['in']);
  }
  skeleton.updateWorldTransform();   // <- this is what solves IK / transform / path
}

const out = { name, anim: animName || '(setup)',
              animations: data.animations.map(a => ({ name: a.name, duration: a.duration })) };
if (anim && fps > 0) {
  let count = Math.max(1, Math.round(anim.duration * fps));
  if (maxFrames > 0) count = Math.min(count, maxFrames);
  out.fps = fps;
  out.duration = anim.duration;
  out.frames = [];
  for (let f = 0; f < count; f++) {
    // duration * f / count rather than f / fps: a LOOPING clip must not repeat its first
    // pose as its last, and this spaces the samples evenly over the real length either way.
    poseAt(anim.duration * f / count);
    out.frames.push(snapshot());
  }
} else {
  poseAt(0);
  out.slots = snapshot();
}
process.stdout.write(JSON.stringify(out));
