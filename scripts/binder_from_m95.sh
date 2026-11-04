#!/bin/bash
# Take the binder driver from the Meizu MX6 Android 13 kernel: it passes the
# sender's security context (FLAT_BINDER_FLAG_TXN_SECURITY_CTX), which
# keystore2 needs to check permissions.
set -e
cd ~/los-kernel/gemini8/kernel-3.18
M=~/los-kernel/m95
for f in drivers/staging/android/binder.c drivers/staging/android/binder_alloc.c \
         drivers/staging/android/binder_alloc.h drivers/staging/android/uapi/binder.h; do
  cp "$M/$f" "$f"
done
git status --short
