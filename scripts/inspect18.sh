#!/bin/bash
ls ~/stockfs
ls ~/stockfs/vendor/lib*/libeffects.so 2>&1
ls ~/stockfs/vendor/etc/init/ | grep -iE "aee|effect"
ls ~/stockfs/vendor/etc/init/hw/
grep -n "libeffects\|libminijail" ~/los/vendor/voyo/x970_t10_97inc/x970_t10_97inc-vendor.mk | head
