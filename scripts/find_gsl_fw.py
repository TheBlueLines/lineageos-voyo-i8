#!/usr/bin/env python3
"""Locate Silead GSL firmware and config tables in the stock kernel Image."""
import array, sys
img = open(sys.argv[1], "rb").read()
base = 0xffffffc000080000
a = array.array("I"); a.frombytes(img[:len(img) & ~3])
n = len(a) // 2
start = None
for i in range(n):
    v = a[2 * i] < 0x100
    if v and start is None:
        start = i
    elif not v and start is not None:
        if i - start > 2000:
            pages = sum(1 for j in range(start, i) if a[2 * j] == 0xf0)
            head = [(hex(a[2 * j]), hex(a[2 * j + 1])) for j in range(start, start + 4)]
            print(f"fw run file={start*8:#x} va={base+start*8:#x} records={i-start} pages={pages} head={head}")
        start = None
for mag in (0xccccccdd, 0xa55a0003, 0x20130424, 0x1cc86fd6):
    for i, x in enumerate(a):
        if x == mag:
            print(f"magic {mag:#x} at file {i*4:#x}: " + " ".join(f"{y:08x}" for y in a[i:i+8]))
