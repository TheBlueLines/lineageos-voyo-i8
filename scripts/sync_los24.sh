#!/bin/bash
# Sync LineageOS 24.0 for the VOYO i8 into ~/los24. Safe to rerun; it resumes.
set -u
L=$HOME/los24
mkdir -p "$L"
cd "$L" || exit 1
if [ ! -f .repo/manifests.git/config ]; then
  yes | repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs \
    --depth=1 --no-clone-bundle -g default,-darwin,-mips || exit 1
fi
for try in 1 2 3 4 5 6; do
  echo "=== sync attempt $try $(date)"
  repo sync -c -j8 --no-tags --no-clone-bundle --optimized-fetch --prune --force-sync 2>&1 | tail -n 25
  if [ "${PIPESTATUS[0]}" -eq 0 ]; then echo "SYNC OK $(date)"; du -sh "$L" "$L/.repo"; exit 0; fi
  sleep 60
done
echo "SYNC FAILED $(date)"; exit 1
