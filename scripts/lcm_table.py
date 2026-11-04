#!/usr/bin/env python3
"""Decode the stock LCM_setting_table and the strings/pointers it needs."""
import re, struct, sys
img = open(sys.argv[1], "rb").read()
sym = {}
for l in open(sys.argv[2]):
    a, t, n = l.split()[:3]
    sym.setdefault(int(a, 16), n)
addrs = sorted(sym)
import bisect
BASE = 0xffffffc000080000
def name(a):
    i = bisect.bisect_right(addrs, a) - 1
    return f"{sym[addrs[i]]}+{a-addrs[i]:#x}"
for a in (0xffffffc0004b1778, 0xffffffc0004b2888, 0xffffffc0004b25f8, 0xffffffc00037f060):
    print(hex(a), name(a))
off = 0xffffffc00141c560 - BASE
for i in range(5):
    cmd, cnt = struct.unpack_from("<IB", img, off + i * 72)
    data = img[off + i * 72 + 5:off + i * 72 + 5 + 64]
    print(f"[{i}] cmd={cmd:#04x} count={cnt} data={data[:max(cnt,1)].hex(' ')}")
def cstr(a):
    b = img[a - BASE:a - BASE + 200]
    return b[:b.find(b'\0')].decode('latin1')
for a in (0xffffffc000efe930, 0xffffffc000efe960, 0xffffffc000efe990):
    print(hex(a), repr(cstr(a)))
print("pinctrl-ish:", sorted({m.decode() for m in re.findall(rb"[A-Za-z0-9_]*(?:lcm|lcd|bias|tp_|tpd)[A-Za-z0-9_]{0,24}", img[0xe00000:0x1100000]) if len(m)>4 and b'%' not in m})[:80])
