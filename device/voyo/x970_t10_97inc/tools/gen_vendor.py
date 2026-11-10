#!/usr/bin/env python3
"""Turn the stock Android 8 vendor image into vendor/voyo/x970_t10_97inc.

The stock blobs link against libraries from the stock /system. Those libraries
are copied into /vendor under same-length names (libutils.so -> l8butils.so)
and every DT_NEEDED and DT_SONAME string is patched in place, so the blobs keep
their Android 8 userspace while AOSP-built vendor modules still get the
Android 13 VNDK. Same length means the ELF layout does not change.

Usage: gen_vendor.py <stock root with system/ and vendor/> <android root>
"""
import os
import re
import shutil
import struct
import sys
import xml.etree.ElementTree as ET

STOCK, TOP = sys.argv[1:3]
DEV = os.path.join(TOP, "device/voyo/x970_t10_97inc")
OUT = os.path.join(TOP, "vendor/voyo/x970_t10_97inc")
PROP = os.path.join(OUT, "proprietary/vendor")
SV, SS = STOCK + "/vendor", STOCK + "/system"

# Android 13 LLNDK: taken from /system at runtime, never copied.
LLNDK = {
    "libc.so", "libm.so", "libdl.so", "liblog.so", "libz.so", "libsync.so",
    "libnativewindow.so", "libEGL.so", "libGLESv1_CM.so", "libGLESv2.so",
    "libGLESv3.so", "libvndksupport.so", "libvulkan.so", "libandroid_net.so",
    "libneuralnetworks.so", "libmediandk.so", "libbinder_ndk.so",
    # VNDK-SP, but one C++ runtime per process: AOSP HALs load the stock
    # modules, and two copies of libc++ clash (std::bad_cast from locale).
    "libc++.so",
}

# Replaced by AOSP modules, or useless on Android 13.
DROP_PATHS = [
    r"^manifest\.xml$", r"^compatibility_matrix\.xml$", r"^build\.prop$",
    r"^default\.prop$", r"^ueventd\.rc$", r"^etc/fstab\.mt6797$",
    r"^lost\+found", r"^etc/selinux/", r"^etc/init/hw/init\.mt6797\.rc$",
    r"^etc/init/hw/init\.mt6797\.usb\.rc$", r"^etc/init/vndservicemanager\.rc$",
    r"^etc/init/android\.hardware\.audio@2\.0-service-mediatek\.rc$",
    r"^bin/hw/android\.hardware\.audio@2\.0-service-mediatek$",
    r"^lib(64)?/hw/android\.hardware\.audio@2\.0-impl",
    r"^lib(64)?/hw/android\.hardware\.audio\.effect@2\.0-impl",
    r"^lib(64)?/hw/android\.hardware\.graphics\.mapper@2\.0-impl",
    # The Android 8 composer wrapper presents before validating, which the
    # MTK HWC rejects; the AOSP service only does that with SKIP_VALIDATE.
    r"^lib(64)?/hw/android\.hardware\.graphics\.composer@2\.1-impl\.so$",
    r"^bin/hw/android\.hardware\.graphics\.composer@2\.1-service$",
    r"^etc/init/android\.hardware\.graphics\.composer@2\.1-service\.rc$",
    r"^bin/sh$", r"^bin/toybox_vendor$", r"^bin/toolbox$", r"^bin/hw/wpa_supplicant_dummy$",
    r"^etc/mkshrc$", r"^app/", r"^overlay/", r"^framework/", r"^etc/gallery/",
    # The AOSP effects HAL needs the Android 13 libeffects.
    r"^lib(64)?/libeffects\.so$",
    # AEE needs private liblog functions, and preloads a vendor library into
    # every process, which Android 13 system binaries cannot load.
    r"^etc/init/aee_aedv(64)?\.rc$", r"^etc/init/hw/init\.aee\.rc$",
    # base_vendor.mk installs the AOSP configstore 1.1 service, which also
    # serves 1.0; the manifest declares it below.
    r"^bin/hw/android\.hardware\.configstore@1\.0-service$",
    r"^etc/init/android\.hardware\.configstore@1\.0-service\.rc$",
]
DROP = [re.compile(p) for p in DROP_PATHS]


def renamed(name):
    return name[0] + "8" + name[2:]


def is_elf(path):
    if os.path.islink(path) or not os.path.isfile(path):
        return False
    with open(path, "rb") as f:
        return f.read(4) == b"\x7fELF"


def elf_dyn(data):
    """Return (dynstr offset, [(tag, value)]) with file offsets."""
    is64 = data[4] == 2
    if is64:
        phoff = struct.unpack_from("<Q", data, 32)[0]
        phsize, phnum = struct.unpack_from("<HH", data, 54)
    else:
        phoff = struct.unpack_from("<I", data, 28)[0]
        phsize, phnum = struct.unpack_from("<HH", data, 42)
    loads, dyn = [], None
    for i in range(phnum):
        off = phoff + i * phsize
        if is64:
            ptype, _, poff, vaddr, _, fsz = struct.unpack_from("<IIQQQQ", data, off)
        else:
            ptype, poff, vaddr, _, fsz = struct.unpack_from("<IIIII", data, off)
        if ptype == 1:
            loads.append((vaddr, poff, fsz))
        elif ptype == 2:
            dyn = (poff, fsz)
    if dyn is None:
        return None, []

    def v2o(v):
        for vaddr, poff, fsz in loads:
            if vaddr <= v < vaddr + fsz:
                return v - vaddr + poff
        return None

    ents = []
    esz, fmt = (16, "<QQ") if is64 else (8, "<II")
    for p in range(dyn[0], dyn[0] + dyn[1], esz):
        tag, val = struct.unpack_from(fmt, data, p)
        if tag == 0:
            break
        ents.append((tag, val))
    strtab = next((v2o(v) for t, v in ents if t == 5), None)
    return strtab, ents


def cstr(data, off):
    return data[off:data.index(b"\0", off)].decode("latin1")


def needed(path):
    with open(path, "rb") as f:
        data = f.read()
    strtab, ents = elf_dyn(data)
    if strtab is None:
        return []
    return [cstr(data, strtab + v) for t, v in ents if t == 1]


def patch(path, names):
    with open(path, "rb") as f:
        data = bytearray(f.read())
    strtab, ents = elf_dyn(bytes(data))
    if strtab is None:
        return
    changed = False
    for t, v in ents:
        if t not in (1, 14):  # DT_NEEDED, DT_SONAME
            continue
        off = strtab + v
        s = cstr(data, off)
        if s in names:
            new = names[s].encode()
            assert len(new) == len(s)
            data[off:off + len(s)] = new
            changed = True
    if changed:
        os.chmod(path, 0o644)
        with open(path, "wb") as f:
            f.write(data)


def rel_walk(root):
    for d, _, files in os.walk(root):
        for f in files:
            p = os.path.join(d, f)
            yield os.path.relpath(p, root), p


# 1. Stock vendor files.
shutil.rmtree(OUT, ignore_errors=True)
os.makedirs(PROP)
vendor_names = {}
vendor_links = {}
symlinks = 0
for rel, p in rel_walk(SV):
    if any(r.search(rel) for r in DROP):
        continue
    if os.path.islink(p):
        link = os.readlink(p)
        if link.startswith("/vendor/"):
            # Absolute links (hw/vulkan.mt6797.so -> /vendor/lib*/egl/libGLES_mali.so)
            # point outside the stock tree here; keep them as links so the
            # driver is mapped once when a process uses both GLES and Vulkan.
            vendor_links[rel] = link
            continue
        target = os.path.normpath(os.path.join(os.path.dirname(p), link))
        if not os.path.isfile(target):
            symlinks += 1
            continue
        src = target
    else:
        src = p
    dst = os.path.join(PROP, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)
    vendor_names.setdefault(os.path.basename(rel), rel)

# 1b. Android 8 libhidltransport loads the shared memory HAL from /system/lib*/hw,
# which vendor processes cannot reach on Android 13. Give them their own copy.
for bits in ("lib", "lib64"):
    src = os.path.join(SS, bits, "hw", "android.hidl.memory@1.0-impl.so")
    os.makedirs(os.path.join(PROP, bits, "hw"), exist_ok=True)
    shutil.copyfile(src, os.path.join(PROP, bits, "hw", "android.hidl.memory@1.0-impl.so"))

# 2. Closure of what they need from the stock /system.
wanted = {"lib": set(), "lib64": set()}
for rel, p in rel_walk(PROP):
    if not is_elf(p):
        continue
    bits = "lib64" if open(p, "rb").read(5)[4] == 2 else "lib"
    wanted[bits].update(needed(p))
names = {}
for bits, todo in wanted.items():
    todo = set(todo)
    seen = set()
    while todo:
        lib = todo.pop()
        if lib in seen or lib in LLNDK:
            continue
        seen.add(lib)
        if os.path.exists(os.path.join(PROP, bits, lib)) or os.path.exists(os.path.join(PROP, bits, "hw", lib)):
            continue
        src = os.path.join(SS, bits, lib)
        if os.path.islink(src):
            src = os.path.normpath(os.path.join(os.path.dirname(src), os.readlink(src)))
        if not os.path.isfile(src):
            print(f"MISSING {bits}/{lib}")
            continue
        names[lib] = renamed(lib)
        dst = os.path.join(PROP, bits, names[lib])
        shutil.copyfile(src, dst)
        todo.update(needed(dst))
print("copied", len(names), "Android 8 libraries")

# 3. Patch every ELF. Blobs that use a function Android 13 removed or hides
# from vendor code get a same-length shim instead of the library they name;
# the shim provides the function and needs the real library for the rest.
SHIMS = {
    "libdl.so": ("l8bdl.so", (b"android_get_exported_namespace", b"android_create_namespace",
                              b"android_link_namespaces", b"android_init_anonymous_namespace")),
    "libEGL.so": ("l8bEGL.so", (b"_Z35eglQueryStringImplementationANDROIDPvi",)),
    "libc.so": ("l8bc.so", (b"get_malloc_leak_info", b"free_malloc_leak_info", b"malloc_iterate",
                            b"malloc_disable", b"malloc_enable", b"malloc_backtrace",
                            b"__cxa_demangle")),
}
for rel, p in rel_walk(PROP):
    if is_elf(p):
        with open(p, "rb") as f:
            data = f.read()
        shims = {lib: shim for lib, (shim, funcs) in SHIMS.items()
                 if any(fn + b"\0" in data for fn in funcs)}
        patch(p, dict(names, **shims))

# 4. Keep the stock vndservicemanager under its own name: the Android 13 one
# rejects Android 8 parcels, and the AOSP binary owns the usual path.
os.rename(os.path.join(PROP, "bin/vndservicemanager"), os.path.join(PROP, "bin/vndservicemanager_o"))

# 5. Media profiles under the name Android 13 looks for.
shutil.copyfile(os.path.join(PROP, "etc/media_profiles.xml"), os.path.join(PROP, "etc/media_profiles_V1_0.xml"))

# 5b. The OMX service's Android 8 minijail cannot parse the Android 13
# /system/etc/seccomp_policy/mediacodec.policy (MREMAP_MAYMOVE, @include), so
# the service aborted and restarted every 5 s. Point it at a vendor copy it can
# parse; the path has the same length.
omx = os.path.join(PROP, "bin/hw/android.hardware.media.omx@1.0-service")
with open(omx, "rb") as f:
    data = f.read()
old, new = b"/system/etc/seccomp_policy/mediacodec.policy\0", b"/vendor/etc/seccomp_policy/omx-base-o.policy\0"
assert len(old) == len(new) and data.count(old) == 1, "OMX seccomp path not found"
with open(omx, "wb") as f:
    f.write(data.replace(old, new))
shutil.copyfile(os.path.join(DEV, "seccomp/omx-base-o.policy"), os.path.join(PROP, "etc/seccomp_policy/omx-base-o.policy"))

# 5b1. libmnl tears down mutexes 3, 5 and 6 of its table on two paths each (the
# GPS stop, mtk_gps_uninit, the agent thread's exit). Android 8 returned EBUSY
# for that, Android 13 aborts, so mnld died whenever a client stopped GPS. Every
# destroy goes through one wrapper: replace its blx with "movs r0, #0; nop".
# Bionic mutexes hold no resources and the next start re-inits the table.
mnl = os.path.join(PROP, "lib/libmnl.so")
with open(mnl, "rb") as f:
    data = f.read()
old = bytes.fromhex("064b7b4403eb8000" "f6f728ea" "002814bf")
new = bytes.fromhex("064b7b4403eb8000" "002000bf" "002814bf")
assert data.count(old) == 1, "libmnl mutex destroy wrapper not found"
data = data.replace(old, new)
# Satellites send the week modulo 1024. With no reference time, libmnl picks the
# era from a window that ended in 2025, so fixes read 1024 weeks early (2007).
# Two copies pick +2048 below a threshold and +1024 above it: always use +2048,
# which maps every week into 2019-2038.
for old, new in (("00f5006000f58060", "00f5006000f50060"),
                 ("02f5006202f58062", "02f5006202f50062")):
    old, new = bytes.fromhex(old), bytes.fromhex(new)
    assert data.count(old) == 1, "libmnl week era site not found"
    data = data.replace(old, new)
with open(mnl, "wb") as f:
    f.write(data)

# 5b1a. The GPS HAL forwards measurements and navigation messages through
# callback tables it never checks. mnld keeps sending them after the HAL restarts,
# and not every slot is filled, so a null callback killed the HAL and then
# system_server. Guard the four call sites: each loads the table and its callback,
# skips the call if either is null, and gives up the stack canary compare for the
# room. These functions only copy fixed-size structs to their own stack.
gps = os.path.join(PROP, "lib64/hw/gps.mt6797.so")
with open(gps, "rb") as f:
    data = f.read()
for old, new in (
    ("083140f9e9a30ff9eaa70ff9ebab0ff9080540f900013fd648d03bd5081540f9a9835ef81f0109ebc1000054", "083140f9480100b4080540f9080100b4e9a30ff9eaa70ff9ebab0ff900013fd61f2003d51f2003d51f2003d5"),
    ("083140f9e92b12f9ea2f12f9eb6324b9080940f900013fd648d03bd5081540f9a9835ef81f0109ebc1000054", "083140f9480100b4080940f9080100b4e92b12f9ea2f12f9eb6324b900013fd61f2003d51f2003d51f2003d5"),
    ("293540f9e0230091ea2f0079eba301a9e8031b32290540f9e80700f920013fd6681640f9a9835ef81f0109eba1000054", "293540f9690100b4290540f9290100b4e0230091ea2f0079eba301a9e8031b32e80700f920013fd61f2003d51f2003d5"),
    ("4a3540f908144079e91300f9091840790b1c4079e00300914a0940f9e8170079e91b0079eb1f007940013fd6681640f9a9835ef81f0109eba1000054", "4a3540f9ca0100b44a0940f98a0100b408144079e91300f9091840790b1c4079e0030091e8170079e91b0079eb1f007940013fd61f2003d51f2003d5"),
):
    old, new = bytes.fromhex(old), bytes.fromhex(new)
    assert data.count(old) == 1, "GPS HAL callback site not found"
    data = data.replace(old, new)
with open(gps, "wb") as f:
    f.write(data)

# 5b1b. mnld's four navigation message loops copy the payload to a data pointer
# they zero and never set, so the first real message segfaulted it, and the same
# pointer then goes to the HAL. Load the source buffer in its place: the copy
# becomes a no-op on itself and the HAL gets the real payload.
mnld = os.path.join(PROP, "bin/mnld")
with open(mnld, "rb") as f:
    data = f.read()
old = bytes.fromhex("379f079942463846")
new = bytes.fromhex("079f079942463846")
assert data.count(old) == 4, "mnld navigation copy sites not found"
with open(mnld, "wb") as f:
    f.write(data.replace(old, new))

# 5b1c. Android 13 no longer builds an A2DP audio module for this configuration,
# so use the stock one. Copied after the renames above: it only needs VNDK
# libraries and libchrome, which vendor processes cannot load. It imports just
# logging::LogMessage from libchrome, on a CHECK failure path, so those symbols
# become weak and the DT_NEEDED entry names liblog, which it needs anyway.
a2dp = os.path.join(PROP, "lib/hw/audio.a2dp.default.so")
shutil.copyfile(os.path.join(SS, "lib/hw/audio.a2dp.default.so"), a2dp)
with open(a2dp, "rb") as f:
    data = bytearray(f.read())
strtab, ents = elf_dyn(bytes(data))
libs = {cstr(data, strtab + v): v for t, v in ents if t == 1}
old, new = struct.pack("<II", 1, libs["libchrome.so"]), struct.pack("<II", 1, libs["liblog.so"])
assert data.count(old) == 1, "A2DP libchrome entry not found"
data[data.index(old):data.index(old) + len(old)] = new
for sym in (b"_ZN7logging10LogMessageC1EPKciS2_", b"_ZN7logging10LogMessageD1Ev"):
    name = data.index(sym + b"\0", strtab) - strtab
    old = struct.pack("<IIIBBH", name, 0, 0, 0x12, 0, 0)  # undefined, global function
    assert data.count(old) == 1, "A2DP libchrome symbol not found"
    data[data.index(old) + 12] = 0x22  # weak function
with open(a2dp, "wb") as f:
    f.write(data)

# 5c. camerahalserver used to segfault in its sensor search: the kernel had no
# GC5005/GC2235 drivers and returned a 216-byte sensor info struct where the
# stock HAL expects 160 bytes. Fixed in the kernel (scripts/camera_kernel.sh),
# so the stock rc is used unchanged and the service starts with class main.

# 5b2. wpa_supplicant keeps its config and sockets in /data/misc/wifi, which is
# core data: enforcing SELinux stops vendor_init from creating it, so after a
# /data wipe Wi-Fi had nowhere to start. Move it to /data/vendor/wifi/wpa,
# which init.voyo.rc.in creates.
rc = os.path.join(PROP, "etc/init/hw/init.connectivity.rc")
src = open(rc).read()
src, n = re.subn(r"^\s*mkdir /data/misc/(wifi|wifi/sockets|wpa_supplicant) .*\n", "", src, flags=re.M)
assert n == 3, "init.connectivity.rc mkdirs not found"
assert src.count("/data/misc/wifi/") == 4, "init.connectivity.rc wpa_supplicant paths not found"
with open(rc, "w", newline="\n") as f:
    f.write(src.replace("/data/misc/wifi/", "/data/vendor/wifi/wpa/"))

# 6. Stock vendor properties, minus identity and anything we set ourselves.
props = []
for f in ("default.prop", "build.prop"):
    for line in open(os.path.join(SV, f), errors="replace"):
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k = line.split("=", 1)[0]
        if re.match(r"dalvik\.|ro\.(build|product|bootimage|vendor\.build|vendor\.product|secure|debuggable|adb|treble|zygote)", k):
            continue
        if k in ("persist.sys.usb.config", "ro.hardware.egl", "dalvik.vm.dex2oat-Xms"):
            continue
        props.append(line)
with open(os.path.join(OUT, "stock-vendor.prop"), "w", newline="\n") as f:
    f.write("\n".join(dict.fromkeys(props)) + "\n")

# 7. Install rules.
rules = sorted(rel for rel, _ in rel_walk(PROP))
with open(os.path.join(OUT, "x970_t10_97inc-vendor.mk"), "w", newline="\n") as f:
    f.write("# Generated by device/voyo/x970_t10_97inc/tools/gen_vendor.py\n")
    f.write("PRODUCT_COPY_FILES += \\\n")
    for r in rules:
        f.write(f"    vendor/voyo/x970_t10_97inc/proprietary/vendor/{r}:$(TARGET_COPY_OUT_VENDOR)/{r} \\\n")
    f.write("\n")
with open(os.path.join(OUT, "Android.mk"), "w", newline="\n") as f:
    f.write("# Generated by device/voyo/x970_t10_97inc/tools/gen_vendor.py\n")
    f.write("ifeq ($(TARGET_DEVICE),x970_t10_97inc)\n")
    for rel, link in sorted(vendor_links.items()):
        f.write(f"VOYO_VENDOR_LINKS += $(TARGET_OUT_VENDOR)/{rel}\n"
                f"$(TARGET_OUT_VENDOR)/{rel}:\n"
                f"\t@mkdir -p $(dir $@)\n\t$(hide) ln -sf {link} $@\n")
    f.write("ALL_DEFAULT_INSTALLED_MODULES += $(VOYO_VENDOR_LINKS)\nendif\n")
with open(os.path.join(OUT, "BoardConfigVendor.mk"), "w", newline="\n") as f:
    f.write("TARGET_VENDOR_PROP += vendor/voyo/x970_t10_97inc/stock-vendor.prop\n")
print("vendor files", len(rules), "links", len(vendor_links), "skipped dangling links", symlinks)

# 8. VINTF manifest from the stock one.
tree = ET.parse(os.path.join(SV, "manifest.xml"))
root = tree.getroot()
root.set("target-level", "3")
for tag in ("sepolicy", "vndk", "kernel"):
    for el in root.findall(tag):
        root.remove(el)
DROP_HALS = {
    # The stock RIL still registers IOemHook; Android 13 has no client for it.
    "android.hardware.radio.deprecated",
    "android.hardware.biometrics.fingerprint", "android.hardware.broadcastradio",
    "android.hardware.soundtrigger",
}
# configstore: the AOSP 1.1 service (base_vendor.mk) aborts every 5 s unless
# the manifest declares it. FCM level 3 allows 1.0-1.
BUMP = {"android.hardware.audio": "6.0", "android.hardware.audio.effect": "6.0",
        "android.hardware.configstore": "1.1"}
for hal in list(root.findall("hal")):
    name = hal.findtext("name")
    if name in DROP_HALS:
        root.remove(hal)
    elif name in BUMP:
        hal.find("version").text = BUMP[name]
health = ET.fromstring(
    '<hal format="hidl"><name>android.hardware.health</name><transport>hwbinder</transport>'
    "<version>2.1</version><interface><name>IHealth</name><instance>default</instance>"
    "</interface></hal>")
root.append(health)
ET.indent = getattr(ET, "indent", lambda *a, **k: None)
ET.indent(tree)
tree.write(os.path.join(DEV, "manifest.xml"), encoding="unicode")

# 9. Device init from the stock one.
src = open(os.path.join(SV, "etc/init/hw/init.mt6797.rc"), errors="replace").read()
src = src.replace("import /FWUpgradeInit.rc\n", "")
src = re.sub(r"^\s*exec /system/bin/tune2fs.*\n", "", src, flags=re.M)
src = re.sub(r"^\s*exec .*/system/bin/.*\n", "", src, flags=re.M)
# MediaTek-only init command, gone in Android 13. The kernel and ueventd
# create these nodes; enforcing SELinux doesn't let vendor_init exec toybox.
src, n = re.subn(r"^(\s*)mknod (\S+)\s+c (\d+) (\d+);?\s*$", r"\1# mknod \2 (ueventd)", src, flags=re.M)
assert n == 3, "init.mt6797.rc mknods not found"
# Writes enforcing SELinux denies to vendor_init: core /data dirs (Wi-Fi moved
# in 5b2; DHCP, DRM, the MTK Bluetooth cache and the Trustonic registry are
# created by their own owners or unused), the stock CD-ROM image mount, and a
# vm sysctl Android 13 sets itself.
for pat in (r"mkdir /mnt/cd-rom ", r"mount iso9660 loop@/vendor/etc/iAmCdRom\.iso ",
            r"chmod 0660 /data/misc/wifi/p2p_supplicant\.conf$", r"mkdir /data/drm/wv ",
            r"mkdir /data/misc/dhcp ", r"chown dhcp wifi /data/misc/dhcp$",
            r"mkdir /data/@btmtk ", r"chown bluetooth bluetooth /data/@btmtk/",
            r"mkdir /data/app/mcRegistry", r"write /proc/sys/vm/dirty_writeback_centisecs "):
    src, n = re.subn(r"^[ \t]*" + pat + r".*\n", "", src, flags=re.M)
    assert n, f"init.mt6797.rc: {pat} not found"
extra = open(os.path.join(DEV, "rootdir/init.voyo.rc.in")).read()
with open(os.path.join(DEV, "rootdir/init.mt6797.rc"), "w", newline="\n") as f:
    f.write(extra + "\n" + src)
shutil.copyfile(os.path.join(SV, "ueventd.rc"), os.path.join(DEV, "rootdir/ueventd.mt6797.rc"))
print("done")
