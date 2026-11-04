#!/usr/bin/env python3
"""List the MTK display ioctl numbers (type 'O', nr 201-240) that an arm64
kernel Image or blob builds with movz/movk, with their argument sizes.
Usage: ioctl_sizes.py <Image or .so> [...]"""
import struct
import sys
from collections import defaultdict


def scan(path):
    data = open(path, "rb").read()
    found = defaultdict(set)
    n = len(data) // 4
    words = struct.unpack_from(f"<{n}I", data)
    for i, w in enumerate(words[:-4]):
        # movz Wd/Xd, #imm16 (hw=0)
        if (w & 0x7FE00000) != 0x52800000:
            continue
        lo = (w >> 5) & 0xFFFF
        if lo >> 8 != 0x4F or not 201 <= (lo & 0xFF) <= 240:
            continue
        rd = w & 0x1F
        for v in words[i + 1:i + 4]:
            # movk Wd/Xd, #imm16, lsl #16 into the same register
            if (v & 0x7FE00000) == 0x72A00000 and (v & 0x1F) == rd:
                hi = (v >> 5) & 0xFFFF
                cmd = (hi << 16) | lo
                found[lo & 0xFF].add((cmd >> 30, (cmd >> 16) & 0x3FFF))
                break
    return found


results = [scan(p) for p in sys.argv[1:]]
print("nr  " + "  ".join(f"{p[-28:]:>28}" for p in sys.argv[1:]))
for nr in sorted(set().union(*results)):
    cols = []
    for r in results:
        cols.append(",".join(f"dir{d}/{s}" for d, s in sorted(r.get(nr, ()))) or "-")
    print(f"{nr:3d} " + "  ".join(f"{c:>28}" for c in cols))
