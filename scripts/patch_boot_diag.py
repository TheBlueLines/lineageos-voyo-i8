#!/usr/bin/env python3
"""Add a log-collecting rule to init.rc in a gzip newc ramdisk.
Usage: patch_boot_diag.py <ramdisk.gz> <output.gz>"""
import gzip
import sys

RULE = b"""
# voyo bring-up: keep the logs of the boot that failed before this one.
on property:sys.boot_completed=1
    copy /dev/block/mmcblk0p3 /cache/voyo-expdb.bin
    copy /sys/fs/pstore/console-ramoops /cache/voyo-pstore
    copy /sys/fs/pstore/console-ramoops-0 /cache/voyo-pstore-0
    copy /dev/block/mmcblk0p3 /data/anr/voyo-expdb.bin
    copy /sys/fs/pstore/console-ramoops /data/anr/voyo-pstore
    chmod 0644 /data/anr/voyo-expdb.bin
    chmod 0644 /data/anr/voyo-pstore
"""


def align(n):
    return (n + 3) & ~3


src = gzip.open(sys.argv[1]).read()
out = bytearray()
pos = 0
patched = False
while True:
    hdr = src[pos:pos + 110]
    assert hdr[:6] == b"070701", f"bad cpio magic at {pos}"
    fields = [int(hdr[6 + i * 8:14 + i * 8], 16) for i in range(13)]
    filesize, namesize = fields[6], fields[11]
    name = src[pos + 110:pos + 110 + namesize - 1]
    data_off = align(pos + 110 + namesize)
    data = src[data_off:data_off + filesize]
    pos = align(data_off + filesize)
    if name == b"init.rc":
        data += RULE
        fields[6] = len(data)
        patched = True
    out += b"070701" + b"".join(b"%08X" % f for f in fields)
    out += name + b"\0"
    out += b"\0" * (align(len(out)) - len(out))
    out += data
    out += b"\0" * (align(len(out)) - len(out))
    if name == b"TRAILER!!!":
        break
assert patched, "init.rc not found"
with gzip.GzipFile(sys.argv[2], "wb", mtime=0) as f:
    f.write(bytes(out))
print("ramdisk", len(src), "->", len(out))
