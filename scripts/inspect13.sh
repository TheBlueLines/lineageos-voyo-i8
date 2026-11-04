#!/bin/bash
V=~/los/vendor/voyo/x970_t10_97inc
ls $V; P=$(find $V -type d -name egl | head -3); echo "egl dirs: $P"; for d in $P; do ls $d; done
echo "--- need android_get_exported_namespace:"
find $V -type f \( -name '*.so' -o -path '*/bin/*' \) | while read f; do
  readelf --dyn-syms -W "$f" 2>/dev/null | grep -q ' UND android_get_exported_namespace' && echo "$f $(readelf -d "$f" | grep -c 'NEEDED.*\[libdl.so\]')"
done
echo "--- props"
grep -rn "egl" ~/los/device/voyo/x970_t10_97inc/*.prop ~/los/device/voyo/x970_t10_97inc/device.mk
grep -rn "vendor.prop\|system.prop\|PROP" ~/los/device/voyo/x970_t10_97inc/BoardConfig.mk ~/los/device/voyo/x970_t10_97inc/device.mk
