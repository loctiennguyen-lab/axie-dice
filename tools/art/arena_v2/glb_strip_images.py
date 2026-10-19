"""Drop embedded image bytes from a GLB whose images also carry a `uri` (Blender's
export_keep_originals writes both). Godot loads the uri file, so the embedded copy is dead weight.
Pure stdlib; runs in Blender's Python or plain python3:  python3 glb_strip_images.py file.glb
"""
import json
import struct
import sys


def strip(path):
    data = open(path, 'rb').read()
    magic, version, _length = struct.unpack('<III', data[:12])
    assert magic == 0x46546C67 and version == 2
    jlen, jtype = struct.unpack('<II', data[12:20])
    gltf = json.loads(data[20:20 + jlen])
    off = 20 + jlen
    blen, btype = struct.unpack('<II', data[off:off + 8])
    bin_ = data[off + 8:off + 8 + blen]

    drop = set()
    for img in gltf.get('images', []):
        if 'uri' in img and 'bufferView' in img:
            drop.add(img.pop('bufferView'))
            img.pop('mimeType', None)
    if not drop:
        return 0
    remap = {}
    views = []
    out = bytearray()
    for i, bv in enumerate(gltf['bufferViews']):
        if i in drop:
            continue
        chunk = bin_[bv.get('byteOffset', 0):bv.get('byteOffset', 0) + bv['byteLength']]
        while len(out) % 4:
            out.append(0)
        bv = dict(bv)
        bv['byteOffset'] = len(out)
        out += chunk
        remap[i] = len(views)
        views.append(bv)
    while len(out) % 4:
        out.append(0)
    gltf['bufferViews'] = views
    gltf['buffers'][0]['byteLength'] = len(out)
    for acc in gltf.get('accessors', []):
        if 'bufferView' in acc:
            acc['bufferView'] = remap[acc['bufferView']]
    for img in gltf.get('images', []):
        if 'bufferView' in img:
            img['bufferView'] = remap[img['bufferView']]
    js = json.dumps(gltf, separators=(',', ':')).encode()
    while len(js) % 4:
        js += b' '
    total = 12 + 8 + len(js) + 8 + len(out)
    with open(path, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, total))
        f.write(struct.pack('<II', len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack('<II', len(out), 0x004E4942))
        f.write(out)
    return len(drop)


if __name__ == '__main__':
    for p in sys.argv[1:]:
        print(p, 'dropped', strip(p))
