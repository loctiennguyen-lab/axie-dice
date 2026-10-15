# Web-only slim export

Web build only. macOS/Windows keep full quality: they export from the untouched `godot/` tree.

    bash godot/tools/export_web_slim.sh [out_dir]    # default <repo>/web, never deploys

It copies `godot/` to `build/web-stage/` (gitignored), runs `web_slim.py` on the copy, re-imports,
then exports the Web preset from the copy. Nothing in `godot/` changes and the game has no runtime
loader for this. `web_slim.py` does three things (knobs at its top):

1. Arena textures byte-identical to a Land texture (same import params, not embedded in an FBX) get
   their refs pointed at the Land copy; the arena copy is dropped.
2. Lossless 2D textures in vfx / backgrounds/origins / monsters/anim / bosses become lossy WebP (q 0.8).
3. 3D VRAM textures under land/ and atia/ larger than 1024 px after import get `size_limit=1024`.

After changing any knob, re-export and look at the pck size plus an art check. Both scripts are dev
tools and are not shipped (`tools/*` is excluded in all export presets).
