#!/bin/bash
# Regenerate the vendor tree and check symbols against it plus the built system.
bash "/mnt/f/Voyo i8/LineageOS/scripts/setup_tree.sh" | tail -1
O=~/los/out/target/product/x970_t10_97inc
T=/tmp/undefroot; rm -rf $T; mkdir -p $T
ln -s $O/system $T/system
cp -r ~/los/vendor/voyo/x970_t10_97inc/proprietary/vendor $T/vendor
cp -n $O/vendor/lib64/l8b*.so $O/vendor/lib64/libeffects.so $T/vendor/lib64/ 2>/dev/null
cp -n $O/vendor/lib/l8b*.so $O/vendor/lib/libeffects.so $T/vendor/lib/ 2>/dev/null
ls $O/system/apex/ | head -3
python3 "/mnt/f/Voyo i8/LineageOS/scripts/undef_check.py" $T | grep -vE "^(str|mem|stp|__str|__mem)[a-z_]* " | cut -c1-200
