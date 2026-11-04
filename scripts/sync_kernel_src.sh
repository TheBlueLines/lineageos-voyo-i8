#!/bin/bash
# Mirror the Voyo kernel source into the LineageOS tree, without build output.
K=$HOME/los/kernel/voyo/x970_t10_97inc
mkdir -p "$K"
rsync -a --delete --exclude out --exclude .git --exclude Android.mk --exclude '*/Android.bp' \
  ~/los-kernel/gemini8/kernel-3.18/ "$K/"
find "$K" -name Android.mk -delete
find "$K" -name Android.bp -delete
du -sh "$K"
