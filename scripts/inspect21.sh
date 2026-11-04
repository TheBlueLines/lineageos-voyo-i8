#!/bin/bash
A='/mnt/c/Users/David/Voyo i8/LineageOS'
cd /tmp; rm -rf ksplit; mkdir ksplit
zcat ~/los-kernel/gemini8/kernel-3.18/out/arch/arm64/boot/Image.gz > ksplit/gemini.Image
V=~/los/out/target/product/x970_t10_97inc/vendor
python3 "$A/scripts/ioctl_sizes.py" "$A/analysis/Image" ksplit/gemini.Image $V/lib64/hw/hwcomposer.mt6797.so
