#!/bin/bash
# The stock audio HAL is built with the Android 8 audio.h: its stream structs
# end after get_mmap_position, and its device has no get_microphones. Skip the
# later methods when ro.vendor.audio.legacy_oreo_abi is set, as the Nougat mode
# already does.
set -e
cd ~/los/hardware/interfaces/audio/core/all-versions/default
grep -q legacy_oreo_abi PrimaryDevice.cpp && { echo "already patched"; exit 0; }
python3 - <<'P'
import re

def edit(path, pairs, count=None):
    s = open(path).read()
    for old, new in pairs:
        n = s.count(old)
        assert n >= 1, (path, old)
        s = s.replace(old, new)
    open(path, "w").write(s)

edit("include/core/default/Device.h", [
    ("    explicit Device(audio_hw_device_t* device, bool hasNougatAbi = false);",
     "    explicit Device(audio_hw_device_t* device, bool hasNougatAbi = false,\n"
     "                    bool hasOreoAbi = false);"),
    ("    bool hasNougatAbi() const { return mHasNougatAbi; }",
     "    bool hasNougatAbi() const { return mHasNougatAbi; }\n"
     "    // Streams of a Nougat or Oreo HAL end before update_*_metadata.\n"
     "    bool hasLegacyStreamAbi() const { return mHasNougatAbi || mHasOreoAbi; }"),
    ("    const bool mHasNougatAbi;",
     "    const bool mHasNougatAbi;\n    const bool mHasOreoAbi;"),
])
edit("Device.cpp", [
    ("Device::Device(audio_hw_device_t* device, bool hasNougatAbi)\n"
     "    : mIsClosed(false), mDevice(device), mHasNougatAbi(hasNougatAbi) {}",
     "Device::Device(audio_hw_device_t* device, bool hasNougatAbi, bool hasOreoAbi)\n"
     "    : mIsClosed(false), mDevice(device), mHasNougatAbi(hasNougatAbi), mHasOreoAbi(hasOreoAbi) {}"),
    ("    if (!mHasNougatAbi && mDevice->get_microphones != NULL &&",
     "    if (!hasLegacyStreamAbi() && mDevice->get_microphones != NULL &&"),
])
for f in ("StreamIn.cpp", "StreamOut.cpp"):
    edit(f, [("mDevice->hasNougatAbi()", "mDevice->hasLegacyStreamAbi()")])
edit("PrimaryDevice.cpp", [
    ("// ro.vendor.audio.legacy_nougat_abi marks the primary legacy HAL as a Nougat build, see\n"
     "// Device::hasNougatAbi(). The other modules loaded by this service are not affected.",
     "// ro.vendor.audio.legacy_nougat_abi and ro.vendor.audio.legacy_oreo_abi mark the primary\n"
     "// legacy HAL as a Nougat or Oreo build, see Device::hasNougatAbi() and\n"
     "// Device::hasLegacyStreamAbi(). The other modules loaded by this service are not affected."),
    ("    : mDevice(new Device(device, property_get_bool(\"ro.vendor.audio.legacy_nougat_abi\", false))) {",
     "    : mDevice(new Device(device, property_get_bool(\"ro.vendor.audio.legacy_nougat_abi\", false),\n"
     "                         property_get_bool(\"ro.vendor.audio.legacy_oreo_abi\", false))) {"),
])
P
grep -n "hasNougatAbi()" StreamIn.cpp StreamOut.cpp | head -3
cd ~/los/hardware/interfaces
git commit -qam "audio: support a legacy HAL built with the Oreo audio.h" && git log --oneline -2
git format-patch -2 -o "/mnt/c/Users/David/Voyo i8/LineageOS/patches/hardware_interfaces" >/dev/null && ls "/mnt/c/Users/David/Voyo i8/LineageOS/patches/hardware_interfaces"
