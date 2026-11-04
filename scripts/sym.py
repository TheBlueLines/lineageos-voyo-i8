#!/usr/bin/env python3
"""Resolve addresses against a System.map: sym.py <System.map> <hex>..."""
import bisect
import sys

syms = []
for line in open(sys.argv[1]):
    a, t, n = line.split()[:3]
    if t in "tT":
        syms.append((int(a, 16), n))
syms.sort()
keys = [s[0] for s in syms]
for arg in sys.argv[2:]:
    v = int(arg, 16)
    if v < 0xffffffc000000000:
        v += 0xffffffc000000000
    i = bisect.bisect_right(keys, v) - 1
    print(f"{v:#x} {syms[i][1]}+{v - syms[i][0]:#x}")
