#!/bin/bash
for k in ~/los-kernel/m95 ~/los-kernel/gemini8/kernel-3.18; do
  echo "== $k"
  grep -rln "TXN_SECURITY_CTX\|txn_security_ctx" $k/drivers/android $k/drivers/staging/android $k/include/uapi/linux/android 2>/dev/null | head
  ls $k/drivers/android 2>/dev/null | head -20
done
ls ~/los-kernel/m95/../ 2>/dev/null; ls "/mnt/c/Users/David/Voyo i8/LineageOS/kernel-port/patches" | head -30
cd ~/los-kernel/m95 && git log --oneline -40 2>/dev/null | grep -iE "binder|secctx|security" | head
