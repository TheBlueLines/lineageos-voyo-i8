#!/bin/bash
python3 "/mnt/c/Users/David/Voyo i8/LineageOS/scripts/undef_check.py" ~/los/out/target/product/x970_t10_97inc > ~/los/undef.txt
wc -l ~/los/undef.txt; cat ~/los/undef.txt | cut -c1-230
