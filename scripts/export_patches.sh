#!/bin/bash
# Save the kernel port outside the WSL distro.
A='/mnt/f/Voyo i8/LineageOS'
cd ~/los-kernel/gemini8
B=$(git rev-list --max-parents=0 HEAD | tail -1)
rm -rf "$A/kernel-port/patches"; mkdir -p "$A/kernel-port/patches"
git format-patch -q --no-renames -o "$A/kernel-port/patches" "$B..HEAD" -- kernel-3.18 ':!kernel-3.18/out'
ls "$A/kernel-port/patches" | wc -l
du -sh "$A/kernel-port/patches"
cp ~/los-kernel/gemini8/kernel-3.18/out/.config "$A/kernel-port/x970_t10_97inc.config"
cp ~/los-kernel/gemini8/kernel-3.18/arch/arm64/configs/x970_t10_97inc_defconfig "$A/kernel-port/"
cp ~/los-kernel/gemini8/kernel-3.18/out/arch/arm64/boot/Image.gz "$A/out/Image-android13-test.gz"
git log --oneline | head -12
