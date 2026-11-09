#!/bin/bash
# Unpack the stock system and vendor images, then report what the vendor blobs need.
A='/mnt/f/Voyo i8/LineageOS'
S=$HOME/stockfs
mkdir -p "$S/vendor" "$S/system"
[ -d "$S/vendor/bin" ] || /usr/sbin/debugfs -R "rdump / $S/vendor" "$A/stock-backup/vendor.bin" 2>/dev/null
[ -d "$S/system/bin" ] || /usr/sbin/debugfs -R "rdump / $S/system" "$A/stock-backup/system.bin" 2>/dev/null
du -sh "$S"/*
cd "$S/vendor"
ls; ls bin | wc -l; ls bin/hw 2>/dev/null | head -40; ls lib | wc -l; ls lib64 | wc -l; ls etc | head -60
RE=$HOME/los-kernel/gcc49/bin/aarch64-linux-android-readelf
python3 - "$S" "$RE" <<'PY'
import os, subprocess, sys, collections
S, RE = sys.argv[1:]
V = S + '/vendor'
have = {}
for root, _, files in os.walk(V):
    for f in files:
        have.setdefault(f, []).append(root)
miss = collections.Counter()
users = collections.defaultdict(list)
n = 0
for root, _, files in os.walk(V):
    for f in files:
        p = os.path.join(root, f)
        if os.path.islink(p):
            continue
        with open(p, 'rb') as h:
            if h.read(4) != b'\x7fELF':
                continue
        n += 1
        o = subprocess.run([RE, '-d', p], capture_output=True, text=True).stdout
        for l in o.splitlines():
            if '(NEEDED)' in l:
                lib = l.split('[')[1].split(']')[0]
                if lib not in have:
                    miss[lib] += 1
                    users[lib].append(f)
print('ELF files', n, 'distinct libs needed from outside /vendor', len(miss))
for k, v in miss.most_common(150):
    print(f'{v:4d} {k}')
PY
