#!/bin/bash
G=~/los-kernel/gemini8/kernel-3.18/drivers/staging/android
M=~/los-kernel/m95/drivers/staging/android
diff -u $G/binder.c $M/binder.c > /tmp/binder.diff
grep -E "^@@" /tmp/binder.diff | head -60
ls $G | grep -i binder; ls $M | grep -i binder
for f in binder_alloc.c binder_alloc.h binder_trace.h; do cmp -s $G/$f $M/$f && echo "$f same" || echo "$f differs"; done
