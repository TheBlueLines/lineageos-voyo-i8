#!/bin/bash
# Build the Gemini-based Voyo kernel. -k collects all errors in one pass.
cd ~/los-kernel/gemini8/kernel-3.18
mkdir -p out
export PATH=$HOME/los-kernel/gcc49/bin:$PATH
M="O=$PWD/out ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- HOSTCFLAGS=-fcommon TARGET_BUILD_VARIANT=user"
make $M x970_t10_97inc_defconfig 2>&1 | tail -2
make $M -k -j14 Image.gz > out/build.log 2>&1
echo "exit=$?"
grep -nE ' error: |fatal error|undefined reference|\*\*\* No rule|Error 1$' out/build.log | cut -c1-150 | head -${1:-40}
ls -la out/arch/arm64/boot/Image.gz 2>/dev/null
