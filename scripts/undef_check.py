#!/usr/bin/env python3
"""List undefined symbols of the vendor ELFs that nothing in their dependency
closure defines, resolving names like the Android linker: /vendor first, then
/system and the runtime APEX. Usage: undef_check.py <product out dir>"""
import os
import subprocess
import sys
from collections import defaultdict

O = sys.argv[1]
SEARCH = {
    "lib64": [f"{O}/vendor/lib64", f"{O}/vendor/lib64/hw", f"{O}/system/lib64",
              f"{O}/system/apex/com.android.runtime/lib64/bionic", f"{O}/system/apex/com.android.runtime/lib64",
              f"{O}/system/apex/com.android.vndk.current/lib64"],
    "lib": [f"{O}/vendor/lib", f"{O}/vendor/lib/hw", f"{O}/system/lib",
            f"{O}/system/apex/com.android.runtime/lib/bionic", f"{O}/system/apex/com.android.runtime/lib",
            f"{O}/system/apex/com.android.vndk.current/lib"],
}
cache = {}


def info(path):
    if path in cache:
        return cache[path]
    needed, defined, undef = [], set(), set()
    out = subprocess.run(["readelf", "-dW", "--dyn-syms", path], capture_output=True, text=True).stdout
    for line in out.splitlines():
        if "(NEEDED)" in line:
            needed.append(line.split("[", 1)[1].rstrip("]"))
            continue
        f = line.split()
        if len(f) >= 8 and f[0].endswith(":") and f[0][:-1].isdigit():
            name = f[7].split("@")[0]
            if f[6] == "UND":
                if f[4] != "WEAK" and name:
                    undef.add(name)
            else:
                defined.add(name)
    cache[path] = (needed, defined, undef)
    return cache[path]


def find(name, bits):
    for d in SEARCH[bits]:
        p = os.path.join(d, name)
        if os.path.isfile(p):
            return p
    return None


missing = defaultdict(set)
for top in (f"{O}/vendor/lib", f"{O}/vendor/lib64", f"{O}/vendor/bin"):
    for d, _, files in os.walk(top):
        for fn in files:
            p = os.path.join(d, fn)
            with open(p, "rb") as f:
                h = f.read(5)
            if h[:4] != b"\x7fELF":
                continue
            bits = "lib64" if h[4] == 2 else "lib"
            needed, _, undef = info(p)
            seen, todo, defs = set(), list(needed), set(info(p)[1])
            while todo:
                n = todo.pop()
                if n in seen:
                    continue
                seen.add(n)
                q = find(n, bits)
                if not q:
                    missing[f"<no lib {n}>"].add(os.path.relpath(p, O))
                    continue
                nd, df, _ = info(q)
                defs |= df
                todo.extend(nd)
            for s in undef - defs:
                missing[s].add(os.path.relpath(p, O))
for s in sorted(missing, key=lambda k: -len(missing[k])):
    users = sorted(missing[s])
    print(f"{s}  [{len(users)}] {' '.join(users[:4])}")
