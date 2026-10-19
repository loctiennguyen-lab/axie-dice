#!/usr/bin/env python3
# Backstop cho tools/build_desktop.sh (chạy sau export): gói có chứa override.cfg không.
# Usage: python3 -I godot/tools/check_export_no_override.py <AxieDice.app | AxieDice.exe>
# Exit: 0 sạch, 1 CÓ override.cfg trong pck, 2 không kiểm được (fail closed).
# macOS: pck nằm ở Contents/Resources/*.pck (embed_pck=false). Windows: pck nhúng cuối exe, trailer
# [pck][int64 cỡ pck little-endian][b"GDPC"], pck bắt đầu ở len-12-cỡ. Chỉ quét phần pck: binary của
# engine có sẵn chuỗi "res://override.cfg" nên quét cả exe sẽ báo sai.
import glob
import os
import sys


def pck_blobs(target):
    if os.path.isdir(target):
        found = sorted(glob.glob(os.path.join(target, "Contents", "Resources", "*.pck")))
        if not found:
            raise ValueError("không thấy .pck trong Contents/Resources")
        return [(p, open(p, "rb").read()) for p in found]
    data = open(target, "rb").read()
    if len(data) < 16 or data[-4:] != b"GDPC":
        raise ValueError("exe không có trailer pck")
    size = int.from_bytes(data[-12:-4], "little")
    start = len(data) - 12 - size
    if size <= 0 or start <= 0 or data[start:start + 4] != b"GDPC":
        raise ValueError("trailer pck không khớp")
    return [(target + " (pck nhúng)", data[start:len(data) - 12])]


def main(argv):
    if len(argv) != 2:
        print("usage: check_export_no_override.py <app|exe>", file=sys.stderr)
        return 2
    try:
        blobs = pck_blobs(argv[1])
    except (OSError, ValueError) as err:
        print(f"check_export_no_override: không kiểm được {argv[1]}: {err}", file=sys.stderr)
        return 2
    for name, blob in blobs:
        if b"res://" not in blob:
            print(f"check_export_no_override: {name} không có res:// nào, trông rỗng", file=sys.stderr)
            return 2
    leaked = [name for name, blob in blobs if b"override.cfg" in blob]
    if leaked:
        print("check_export_no_override: override.cfg CÓ trong " + ", ".join(leaked), file=sys.stderr)
        return 1
    print(f"check_export_no_override: sạch ({len(blobs)} pck)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
