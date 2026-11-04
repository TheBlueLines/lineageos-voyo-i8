#!/bin/bash
# Set up the LineageOS build env. Usage: los_env.sh <command...>
cd ~/los
source build/envsetup.sh > /tmp/envsetup.log 2>&1
lunch lineage_x970_t10_97inc-userdebug > /tmp/lunch.log 2>&1
rc=$?
tail -14 /tmp/lunch.log | cut -c1-140
[ $rc -eq 0 ] || exit $rc
"$@"
