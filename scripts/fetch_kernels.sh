#!/bin/bash
# Fetch the kernel sources and GCC 4.9 toolchain used for the port.
set -u
W=$HOME/los-kernel; mkdir -p "$W"; cd "$W"
clone() { [ -d "$2/.git" ] || git clone -q --depth=1 ${3:+-b "$3"} "https://github.com/$1" "$2" && echo "ok $2"; }
clone nomorecoolnicknames/android_kernel_meizu_m95 m95 lineage-20.0 &
clone dguidipc/gemini-android-kernel-3.18-android8 gemini8 &
clone LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 gcc49 lineage-19.1 &
clone szazs89/kernel_lenovo_TB3_710F tb3 &
wait
du -sh "$W"/*
