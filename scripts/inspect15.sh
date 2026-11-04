#!/bin/bash
O=~/los/out/target/product/x970_t10_97inc
readelf -d $O/system/bin/vold | grep NEEDED | grep -i coredump
ls -la $O/system/bin/vold $O/system.img
find $O/system $O/vendor -name 'libdirect-coredump*' | head
grep -rl "libdirect-coredump" $O/vendor/etc $O/vendor/lib64/*.so 2>/dev/null | head
grep -rn "LD_PRELOAD\|ld.config" $O/vendor/etc/init/hw/init.mt6797.rc $O/vendor/build.prop 2>/dev/null | head
grep -rln "direct-coredump" ~/los/device/voyo ~/los/vendor/voyo/x970_t10_97inc/*.mk 2>/dev/null | head
