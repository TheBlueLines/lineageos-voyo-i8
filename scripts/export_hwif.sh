#!/bin/bash
# Export our own hardware/interfaces commits, on top of the MX6 fork in the manifest.
cd ~/los/hardware/interfaces
O="/mnt/f/Voyo i8/LineageOS/patches/hardware_interfaces"
rm -rf "$O"; mkdir -p "$O"
n=0
for c in $(git log --format=%H --author="TWRP Builder" --reverse); do
  n=$((n + 1)); git format-patch -1 "$c" --start-number $n -o "$O" | sed 's#.*/##'
done
