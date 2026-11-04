#!/bin/bash
# Push the built vendor SELinux policy (and optionally the patched stock rc) to
# the tablet, from LineageOS with root adb or from TWRP. Run from Git Bash.
# Usage: sepolicy_push.sh [path/to/init.mt6797.rc]
set -e
export MSYS_NO_PATHCONV=1
cd '/c/Users/David/Voyo i8/LineageOS'
N=out/selinux/new
rm -rf "$N"; mkdir -p "$N"
wsl -d TWRP-Builder -- bash -c 'cp ~/los/out/target/product/x970_t10_97inc/vendor/etc/selinux/* "/mnt/c/Users/David/Voyo i8/LineageOS/out/selinux/new/"'
if [ "$(adb get-state)" = recovery ]; then
  adb shell 'mount /vendor 2>/dev/null; true'
else
  adb root >/dev/null; adb wait-for-device; adb remount >/dev/null
  # Keep the first backup of what was on the tablet.
  adb shell 'mkdir -p /data/local/tmp/selinux-backup && cp -n /vendor/etc/selinux/* /data/local/tmp/selinux-backup/'
fi
for f in "$N"/*; do adb push "$f" /vendor/etc/selinux/ >/dev/null; done
[ -n "$1" ] && adb push "$1" /vendor/etc/init/hw/init.mt6797.rc >/dev/null
# Explicit labels: TWRP does not relabel pushed files.
adb shell 'cd /vendor/etc/selinux && for f in *; do c=vendor_configs_file; [ $f = vendor_service_contexts ] && c=vendor_service_contexts_file; chcon u:object_r:$c:s0 $f; done; chcon u:object_r:vendor_configs_file:s0 /vendor/etc/init/hw/init.mt6797.rc; sync; md5sum /vendor/etc/selinux/precompiled_sepolicy' | cut -d' ' -f1
md5sum "$N/precompiled_sepolicy" | cut -d' ' -f1
