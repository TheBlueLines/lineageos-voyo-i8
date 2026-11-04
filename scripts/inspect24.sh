#!/bin/bash
F=~/los/out/target/product/x970_t10_97inc/vendor/lib64/hw/hwcomposer.mt6797.so
strings -n 6 $F | grep -nE "job is null|nulljob|getJob|not enable|disabled|plug|session|Session|SESSION|is not ready|no job|drop|bypass|Power|power mode|OVL is|ovl" | head -60
