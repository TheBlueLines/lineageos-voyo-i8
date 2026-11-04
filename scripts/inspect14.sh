#!/bin/bash
cd ~/los/vendor/voyo/x970_t10_97inc/proprietary/vendor
for f in lib64/l8bhidltransport.so lib/l8bui.so lib64/l8bnativeloader.so; do echo "$f: $(readelf -d $f | grep -oE '\[(l8bdl|libdl)\.so\]' | tr '\n' ' ')"; done
grep -n "voyo_diag" etc/init/hw/init.mt6797.rc 2>/dev/null || grep -rln voyo_diag ~/los/vendor/voyo/x970_t10_97inc | head -3
grep -n "CMDLINE" ~/los/device/voyo/x970_t10_97inc/BoardConfig.mk
