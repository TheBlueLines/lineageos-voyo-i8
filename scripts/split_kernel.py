#!/usr/bin/env python3
"""Split an Image.gz-dtb into the kernel Image and its appended DTBs."""
import struct
import sys
import zlib
from pathlib import Path

src, outdir = Path(sys.argv[1]), Path(sys.argv[2])
blob = src.read_bytes()
d = zlib.decompressobj(31)
image = d.decompress(blob)
rest = d.unused_data
(outdir / "Image").write_bytes(image)
print(f"Image {len(image)} bytes, trailing {len(rest)} bytes")
n = 0
pos = rest.find(b"\xd0\x0d\xfe\xed")
while pos >= 0:
    size = struct.unpack(">I", rest[pos + 4:pos + 8])[0]
    (outdir / f"dtb{n}.dtb").write_bytes(rest[pos:pos + size])
    print(f"dtb{n} offset {pos} size {size}")
    n += 1
    pos = rest.find(b"\xd0\x0d\xfe\xed", pos + size)
