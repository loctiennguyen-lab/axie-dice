#!/bin/bash
# Arena v2 textures are 3D-only: VRAM compressed + mipmaps (Godot first imports them as 2D lossless).
# Run after a Godot --import has created the .import files, then import again.
cd "$(dirname "$0")/../../../godot/assets/atia/arena_v2" || exit 1
for f in */textures/*.import; do
  sed -i '' -e 's/^compress\/mode=0/compress\/mode=2/' -e 's/^mipmaps\/generate=false/mipmaps\/generate=true/' \
    -e 's/"vram_texture": false/"vram_texture": true/' "$f"
done
grep -h "compress/mode" */textures/*.import | sort | uniq -c
