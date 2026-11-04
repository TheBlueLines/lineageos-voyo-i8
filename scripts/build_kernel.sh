#!/bin/bash
# Build the Voyo kernel. -k collects all errors in one pass.
cd ~/los-kernel/m95
mkdir -p out
export PATH=$HOME/los-kernel/gcc49/bin:$PATH
M="O=$PWD/out ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- HOSTCFLAGS=-fcommon TARGET_BUILD_VARIANT=userdebug"
make $M x970_t10_97inc_defconfig 2>&1 | tail -3
make $M -k -j14 Image.gz > out/build.log 2>&1
echo "exit=$?"
grep -nE ' error: |\*\*\* |undefined reference|Error [0-9]' out/build.log | cut -c1-150 | head -${1:-40}
ls -la out/arch/arm64/boot/Image.gz 2>/dev/null
