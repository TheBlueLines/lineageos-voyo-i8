#!/bin/bash
# Sync LineageOS 20 for the VOYO i8. Safe to rerun; it resumes.
set -u
L=$HOME/los
mkdir -p "$L/.repo/local_manifests"
cd "$L" || exit 1
if [ ! -f .repo/manifests.git/config ]; then
  yes | repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs \
    --depth=1 --no-clone-bundle -g default,-darwin,-mips || exit 1
fi
cat > .repo/local_manifests/voyo.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="remeizu" fetch="https://github.com/nomorecoolnicknames" />
  <remove-project name="LineageOS/android_hardware_ril" />
  <project path="hardware/ril" name="android_hardware_ril" remote="remeizu" revision="lineage-20.0" />
  <project path="device/meizu/common" name="android_device_meizu_common" remote="remeizu" revision="lineage-20.0" />
</manifest>
EOF
for try in 1 2 3 4 5 6; do
  echo "=== sync attempt $try $(date)"
  repo sync -c -j8 --no-tags --no-clone-bundle --optimized-fetch --prune --force-sync 2>&1 | tail -n 25
  if [ "${PIPESTATUS[0]}" -eq 0 ]; then echo "SYNC OK $(date)"; du -sh "$L" "$L/.repo"; exit 0; fi
  sleep 60
done
echo "SYNC FAILED $(date)"; exit 1
