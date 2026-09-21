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
// Usage: node spine_pose_dump.js <spine-core-3.8.js> <skel-dir> <name> [animation]
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

const skeleton = new spine.Skeleton(data);
skeleton.setToSetupPose();
if (animName) {
  const state = new spine.AnimationState(new spine.AnimationStateData(data));
  state.setAnimation(0, animName, false);
  state.update(0);
  state.apply(skeleton);
}
skeleton.updateWorldTransform();   // <- solves the constraints

const out = { name, anim: animName || '(setup)', slots: [] };
for (const slot of skeleton.drawOrder) {
  const att = slot.getAttachment();
  if (!att) continue;
  if (att instanceof spine.RegionAttachment) {
    const v = new Float32Array(8);
    att.computeWorldVertices(slot.bone, v, 0, 2);
    out.slots.push({ slot: slot.data.name, type: 'region', region: att.region.name,
                     verts: Array.from(v), uvs: Array.from(att.uvs) });
  } else if (att instanceof spine.MeshAttachment) {
    const n = att.worldVerticesLength;
    const v = new Float32Array(n);
    att.computeWorldVertices(slot, 0, n, v, 0, 2);
    out.slots.push({ slot: slot.data.name, type: 'mesh', region: att.region.name,
                     verts: Array.from(v), uvs: Array.from(att.uvs),
                     triangles: Array.from(att.triangles) });
  }
}
out.animations = data.animations.map(a => a.name);
process.stdout.write(JSON.stringify(out));
