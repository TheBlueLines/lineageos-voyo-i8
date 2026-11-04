#!/bin/bash
ls ~/los-kernel/m95-patches; grep -l "TXN_SECURITY_CTX" ~/los-kernel/m95-patches/* 2>/dev/null
G=~/los-kernel/gemini8/kernel-3.18/drivers/staging/android
M=~/los-kernel/m95/drivers/staging/android
wc -l $G/binder.c $M/binder.c
diff -u $G/binder.c $M/binder.c | grep -c "^[-+]"
diff -u $G/uapi/binder.h $M/uapi/binder.h | head -80
