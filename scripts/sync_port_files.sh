#!/bin/bash
# Copy the panel and touch drivers from kernel-port/ into the Gemini tree.
set -e
A='/mnt/c/Users/David/Voyo i8/LineageOS'
K=$HOME/los-kernel/gemini8/kernel-3.18
L=$K/drivers/misc/mediatek/lcm/sharp_wqxganl_dsi_vdo_boe_97inc/sharp_wqxganl_dsi_vdo_boe_97inc.c
T=$K/drivers/input/touchscreen/mediatek/gsl3680/gsl3680_driver.c
ls -la "$L" "$T"
tr -d '\r' < "$A/kernel-port/lcm/sharp_wqxganl_dsi_vdo_boe_97inc.c" > "$L"
tr -d '\r' < "$A/kernel-port/touch/gsl3680_driver.c" > "$T"
cd $K && git diff --stat
