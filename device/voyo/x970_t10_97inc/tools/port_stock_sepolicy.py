#!/usr/bin/env python3
"""Port the stock Android 8 (O, policy 26.0) MediaTek vendor SELinux policy to
Android 13 policy language, for the daemons whose binaries are on /vendor.

usage: port_stock_sepolicy.py STOCK_DIR A13_DIR VENDOR_FILE_LIST OUT_DIR

STOCK_DIR        stock /vendor/etc/selinux (nonplat_sepolicy.cil, nonplat_*contexts)
A13_DIR          built LineageOS 20 policy: plat_sepolicy.cil, plat_pub_versioned.cil,
                 system_ext_sepolicy.cil, vendor_sepolicy.cil, plat_*_contexts,
                 plat_genfs_contexts, system_ext_property_contexts, vendor_*_contexts
VENDOR_FILE_LIST `find /vendor -type f` from the tablet
OUT_DIR          sepolicy directory to write (te + contexts)

What is ported:
- every stock vendor domain whose entry point is a file on /vendor, with all of
  its allow/allowx/dontaudit/type_transition rules;
- rules from platform domains (O names ending in _26_0 mapped to the Android 13
  type of the same name) to those domains and to stock vendor types;
- every stock vendor non-domain type and attribute, with its attributes;
- file, genfs, property, hwservice and vndservice contexts for those types,
  minus entries the Android 13 policy already defines.
A rule is dropped when it names a stock vendor domain that is not ported or an
O platform type that Android 13 no longer has. neverallow rules are dropped.
"""
import os
import re
import sys
from collections import defaultdict

STOCK, A13, VFILES, OUT = sys.argv[1:5]
VER = "_26_0"


# ---------------------------------------------------------------- CIL parsing
def parse_cil(path):
    text = re.sub(r";[^\n]*", "", open(path).read())
    toks = re.findall(r'"[^"]*"|[()]|[^\s()]+', text)
    stmts, stack = [], []
    for t in toks:
        if t == "(":
            stack.append([])
        elif t == ")":
            e = stack.pop()
            if stack:
                stack[-1].append(e)
            else:
                stmts.append(e)
        else:
            stack[-1].append(t)
    return stmts


def names_declared(stmts):
    types, attrs = set(), set()
    for s in stmts:
        if s[0] == "type":
            types.add(s[1])
        elif s[0] == "typeattribute":
            attrs.add(s[1])
    return types, attrs


stock = parse_cil(os.path.join(STOCK, "nonplat_sepolicy.cil"))
s_types, s_attrs = names_declared(stock)

a13_all = set()
a13_public = set()
for f in ("plat_sepolicy.cil", "system_ext_sepolicy.cil", "vendor_sepolicy.cil"):
    t, a = names_declared(parse_cil(os.path.join(A13, f)))
    a13_all |= t | a
pub = parse_cil(os.path.join(A13, "plat_pub_versioned.cil"))
pt, pa = names_declared(pub)
a13_public = {n for n in pt | pa if not re.search(r"_\d+_0$", n)}
a13_public |= {n[:-5] for n in pa if n.endswith("_33_0")}
# Vendor-side Android 13 types (default HALs, Lineage vendor) can be used too.
a13_vendor_t, a13_vendor_a = names_declared(parse_cil(os.path.join(A13, "vendor_sepolicy.cil")))
# The built vendor policy may already contain an earlier run's output; those
# names are ours to declare again.
prev = os.path.join(OUT, "mtk_stock.te")
gen = set()
if os.path.exists(prev):
    gen = set(re.findall(r"^(?:type|attribute) ([^\s,;]+)", open(prev).read(), re.M))
    a13_vendor_t -= gen
    a13_vendor_a -= gen
    a13_all -= gen
# Hand-written device policy, which wins over the stock port.
HAND = os.path.join(os.path.dirname(os.path.abspath(OUT)), "vendor")
a13_usable = a13_public | a13_vendor_t | a13_vendor_a

# Attribute membership in the stock policy (only plain member lists).
members = defaultdict(set)
for s in stock:
    if s[0] == "typeattributeset" and isinstance(s[2], list) and all(isinstance(x, str) for x in s[2]):
        for m in s[2]:
            members[s[1]].add(m)
attrs_of = defaultdict(set)
for a, ms in members.items():
    for m in ms:
        attrs_of[m].add(a)

stock_domains = {t for t in s_types if "domain" in attrs_of[t]}

# ------------------------------------------------- which domains are ported
fc_lines = [l.split() for l in open(os.path.join(STOCK, "nonplat_file_contexts"))
            if l.strip() and not l.lstrip().startswith("#")]
vfiles = [l.strip() for l in open(VFILES) if l.strip()]
entry = {}  # exec type -> domain
for s in stock:
    if s[0] == "typetransition" and len(s) == 5 and s[3] == "process" and s[1] == "init" + VER:
        entry[s[2]] = s[4]

ported = set()
for f in fc_lines:
    ctx = f[-1].split(":")[2]
    if ctx not in entry:
        continue
    rx = re.compile("^" + f[0] + "$")
    if any(rx.match(p) for p in vfiles):
        ported.add(entry[ctx])
# Stock vendor domains that Android 13 already declares (hal_*_default).
reuse_domains = {d for d in stock_domains if d in a13_all}
ported |= reuse_domains

# Name collisions with private Android 13 types: rename the vendor type.
rename = {}
for t in (s_types | s_attrs) - stock_domains:
    if t in a13_all and t not in a13_usable:
        rename[t] = "mtk_" + t


# Stock domains whose job is now done by an Android 13 domain.
ALIAS = {
    # The AOSP audio HAL service loads the stock MTK audio module.
    "mtk_hal_audio": "hal_audio_default",
}


def m(n):
    """Map a stock name to Android 13, or None if it cannot be expressed."""
    if n == "self":
        return n
    if n in ALIAS:
        return ALIAS[n]
    if n.startswith("base_typeattr"):
        return None  # compiler-generated attribute expressions
    if n.endswith(VER):
        b = n[: -len(VER)]
        return b if b in a13_usable else None
    if n in stock_domains:
        return n if n in ported else None
    if n in rename:
        return rename[n]
    if n in s_types or n in s_attrs:
        return n
    # Unversioned platform attribute (domain, appdomain, dev_type ...).
    return n if n in a13_usable else None


dropped = defaultdict(int)


def all_mapped(*ns):
    r = [m(n) for n in ns]
    if None in r:
        for n, x in zip(ns, r):
            if x is None:
                dropped[n] += 1
        return None
    return r


def is_a13(n):
    return n in a13_usable


def is_vendor(n):
    return not n.endswith(VER) and (n in s_types or n in s_attrs) and n not in a13_usable


# Type transitions Android 13 already has: a second one for the same key is an error.
a13_tt = set()
for f in ("plat_sepolicy.cil", "system_ext_sepolicy.cil", "vendor_sepolicy.cil"):
    for t in parse_cil(os.path.join(A13, f)):
        if t[0] == "typetransition" and not (f.startswith("vendor") and t[-1] in gen):
            a13_tt.add(tuple(re.sub(r"_\d+_0$", "", x) if x else x
                             for x in (t[1], t[2], t[3], t[4] if len(t) == 6 else None)))

# ----------------------------------------------------------------- rules
rules = []
used = set()
for s in stock:
    k = s[0]
    if k in ("allow", "dontaudit", "allowx", "typetransition"):
        src, tgt = s[1], s[2]
        # Keep rules that involve a vendor type or ported domain on either side,
        # skip platform-to-platform grants.
        if not (is_vendor(src) or is_vendor(tgt) or src in ported or tgt in ported
                or src in ALIAS or tgt in ALIAS):
            continue
        if k in ("allow", "dontaudit"):
            r = all_mapped(src, tgt)
            if not r:
                continue
            cls, perms = s[3][0], s[3][1]
            rules.append(f"{k} {r[0]} {r[1]}:{cls} {{ {' '.join(perms)} }};")
        elif k == "allowx":
            r = all_mapped(src, tgt)
            if not r:
                continue
            op, cls, spec = s[3]

            def flat(v):
                if isinstance(v, str):
                    return [v]
                if v and v[0] == "range":
                    return [f"{v[1]}-{v[2]}"]
                return [x for e in v for x in flat(e)]
            vals = flat(spec)
            rules.append(f"allowxperm {r[0]} {r[1]}:{cls} {op} {{ {' '.join(vals)} }};")
        else:
            if len(s) == 5:
                r = all_mapped(src, tgt, s[4])
                if not r or (r[0], r[1], s[3], None) in a13_tt:
                    continue
                rules.append(f"type_transition {r[0]} {r[1]}:{s[3]} {r[2]};")
            else:
                r = all_mapped(src, tgt, s[5])
                if not r or (r[0], r[1], s[3], s[4]) in a13_tt:
                    continue
                rules.append(f"type_transition {r[0]} {r[1]}:{s[3]} {r[2]} {s[4]};")
        if k == "typetransition" and ((is_a13(r[-1]) and is_a13(r[0]))
                                      or (src in reuse_domains and r[1] == "tmpfs")):
            rules.pop()  # Android 13 policy decides where its own types go.
            continue
        used.update(x for x in r if x != "self")

# ------------------------------------------------------------ declarations
decl_types = sorted(m(t) for t in s_types if t not in ALIAS and (t not in stock_domains or t in ported)
                    and t not in a13_usable and m(t))
decl_attrs = sorted(m(a) for a in s_attrs if not a.endswith(VER) and a not in a13_usable
                    and not a.startswith("base_typeattr") and m(a))

skip_attrs = {"base_typeattr"}
fc_types = defaultdict(list)
for f in fc_lines:
    fc_types[f[-1].split(":")[2]].append(f[0])

out = []
out.append("# Generated by tools/port_stock_sepolicy.py from the stock Android 8 vendor policy.")
out.append("# Do not edit; put fixes in sepolicy/vendor.\n")
for a in decl_attrs:
    out.append(f"attribute {a};")
out.append("")
for t in decl_types:
    orig = {v: k for k, v in rename.items()}.get(t, t)
    at = set()
    for a in attrs_of[orig]:
        if a.startswith("base_typeattr") or a.endswith(VER):
            continue
        ma = m(a)
        if ma:
            at.add(ma)
    paths = fc_types.get(orig, [])
    if t.endswith("_exec") or any(p.startswith("/(vendor") or p.startswith("/(system\\/vendor") or p.startswith("/vendor") for p in paths):
        at |= {"file_type", "vendor_file_type"}
    if t.endswith("_exec"):
        at.add("exec_type")
    if "property_type" in at:
        at |= {"vendor_property_type", "vendor_restricted_property_type"}
    if not at and t not in ported:
        at.add("file_type")
    out.append(f"type {t}" + (", " + ", ".join(sorted(at)) if at else "") + ";")
out.append("")
# Every ported daemon, for device-wide fixes in sepolicy/vendor.
out.append("attribute mtk_stock_domain;")
for d in sorted(set(decl_types) & ported):
    out.append(f"typeattribute {d} mtk_stock_domain;")
out.append("")
# Attributes on reused (Android 13 declared) domains, e.g. MTK hal attributes.
for d in sorted(reuse_domains):
    for a in sorted(attrs_of[d]):
        ma = m(a)
        if ma and ma in decl_attrs:
            out.append(f"typeattribute {d} {ma};")
out.append("")
seen = set()
for r in rules:
    if r not in seen:
        seen.add(r)
        out.append(r)

os.makedirs(OUT, exist_ok=True)
open(os.path.join(OUT, "mtk_stock.te"), "w", newline="\n").write("\n".join(out) + "\n")

valid = set(decl_types) | a13_usable


def ctx_ok(ctx):
    p = ctx.split(":")
    t = rename.get(p[2], p[2])
    if t not in valid:
        return None
    p[2] = t
    return ":".join(p)


# ------------------------------------------------------------ file_contexts
def norm(rx):
    return rx.replace("/(system\\/vendor|vendor)", "/(vendor|system/vendor)")


# Paths the platform owns on Android 13; the stock labels would override it.
PLATFORM_PATHS = re.compile(r"^/data/(system|app|anr|lost|misc/(wifi|wpa_supplicant))")
existing = set()
for fn in (os.path.join(A13, "plat_file_contexts"), os.path.join(A13, "vendor_file_contexts"),
           os.path.join(HAND, "file_contexts")):
    if not os.path.exists(fn):
        continue
    for l in open(fn):
        if l.strip() and not l.startswith("#"):
            existing.add(norm(l.split()[0]))
fc_out = ["# Generated from the stock vendor file_contexts."]
for f in fc_lines:
    path = norm(f[0])
    if path.startswith("/system/") or path in existing or PLATFORM_PATHS.match(path):
        continue
    c = ctx_ok(f[-1])
    if not c:
        continue
    existing.add(path)
    fc_out.append("\t".join([path] + f[1:-1] + [c]))
open(os.path.join(OUT, "file_contexts"), "w", newline="\n").write("\n".join(fc_out) + "\n")

# ------------------------------------------------------------ genfs_contexts
plat_genfs = set()
for l in open(os.path.join(A13, "plat_genfs_contexts")).readlines() + (
        open(os.path.join(HAND, "genfs_contexts")).readlines()
        if os.path.exists(os.path.join(HAND, "genfs_contexts")) else []):
    p = l.split()
    if len(p) >= 3 and p[0] == "genfscon":
        plat_genfs.add((p[1], p[2]))
g_out = []
for s in stock:
    if s[0] == "genfscon":
        fs, path, ctx = s[1], s[2], s[3]
        t = rename.get(ctx[2], ctx[2])
        if (fs, path) in plat_genfs or t not in valid:
            continue
        g_out.append(f"genfscon {fs} {path} u:object_r:{t}:s0")
open(os.path.join(OUT, "genfs_contexts"), "w", newline="\n").write("\n".join(g_out) + "\n")


# ------------------------------------------------- property/service contexts
def port_ctx(src, existing_files, dst):
    have = set()
    for fn in existing_files:
        p = os.path.join(A13, fn)
        if os.path.exists(p):
            for l in open(p):
                if l.strip() and not l.startswith("#"):
                    have.add(l.split()[0])
    res = []
    for l in open(os.path.join(STOCK, src)):
        p = l.split()
        if not p or p[0].startswith("#") or p[0] in have:
            continue
        c = ctx_ok(p[1])
        if c:
            have.add(p[0])
            res.append(f"{p[0]} {c}")
    open(os.path.join(OUT, dst), "w", newline="\n").write("\n".join(res) + "\n")


port_ctx("nonplat_property_contexts",
         ["plat_property_contexts", "system_ext_property_contexts", "vendor_property_contexts"],
         "property_contexts")
port_ctx("nonplat_hwservice_contexts", ["plat_hwservice_contexts", "vendor_hwservice_contexts"],
         "hwservice_contexts")
port_ctx("vndservice_contexts", ["vndservice_contexts"], "vndservice_contexts")

print("ported domains:", " ".join(sorted(ported - reuse_domains)))
print("reused domains:", " ".join(sorted(reuse_domains)))
print("renamed:", rename)
print("rules:", len(seen), "types:", len(decl_types), "attrs:", len(decl_attrs))
print("dropped names (rule count):")
for n, c in sorted(dropped.items(), key=lambda x: -x[1]):
    print(f"  {c:5d} {n}")
