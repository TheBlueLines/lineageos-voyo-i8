#!/usr/bin/env python3
"""Summarise the LK boots stored in an expdb dump. Usage: lk_log.py <expdb.bin>"""
import sys

b = open(sys.argv[1], "rb").read()
KEYS = ("BOOT_REASON", "lk boot mode", "lk finished", "Kernel Size", "zimage_size",
        "fastboot", "FASTBOOT", "mboot_android", "boot failed", "verified", "jump to K64")
for seg in (0x800000, 0x820000):
    t = b[seg:seg + 0x20000].replace(b"\0", b"").decode("latin1")
    lines = t.replace("\r", "").split("\n")
    print(f"== {seg:#x}: {len(lines)} lines")
    shown = 0
    for l in lines:
        if any(k in l for k in KEYS) and "command buf" not in l and "Cmd process" not in l:
            print(l[:110])
            shown += 1
            if shown > 24:
                break
    print("-- tail")
    for l in lines[-6:]:
        print(l[:110])
