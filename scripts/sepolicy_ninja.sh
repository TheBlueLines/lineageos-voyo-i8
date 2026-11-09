#!/bin/bash
# Rebuild only the vendor SELinux outputs with ninja, skipping Soong/Kati
# regeneration. Only valid while no .bp/.mk or file list changed since the
# last full build. Syncs the device sepolicy dir first.
set -e
L=$HOME/los
A='/mnt/f/Voyo i8/LineageOS/device/voyo/x970_t10_97inc'
rsync -a --delete "$A/sepolicy/" "$L/device/voyo/x970_t10_97inc/sepolicy/"
cd "$L"
P=out/target/product/x970_t10_97inc
N=$(ls -t out/combined-lineage_x970_t10_97inc.ninja | head -1)
prebuilts/build-tools/linux-x86/bin/ninja -f "$N" -j12 \
  $P/vendor/etc/selinux/precompiled_sepolicy \
  $P/vendor/etc/selinux/vendor_file_contexts \
  $P/vendor/etc/selinux/vendor_property_contexts \
  $P/vendor/etc/selinux/vendor_hwservice_contexts \
  $P/vendor/etc/selinux/vndservice_contexts \
  $P/vendor/etc/selinux/vendor_sepolicy.cil "$@" 2>&1 | grep -vE '^\[' | cut -c1-400 | tail -40
echo "ninja exit: ${PIPESTATUS[0]}"
