#!/bin/bash
cd ~/los-kernel/gemini8/kernel-3.18
grep -n "ffs_user_copy_worker" -A40 drivers/usb/gadget/function/f_fs.c | head -60
