#!/bin/bash
# Add the Android 13 kernel features to the Gemini-based tree. Safe to rerun.
set -e
A='/mnt/f/Voyo i8/LineageOS'
P=~/los-kernel/m95-patches
cd ~/los-kernel/gemini8/kernel-3.18

for n in 0004 0028 0030 0036 0044 0045; do
  f=$(ls "$P"/$n-*.patch)
  if git log --format=%s -n 200 | grep -qF "$(sed -n 's/^Subject: \[PATCH[^]]*\] //p' "$f" | head -1)"; then continue; fi
  git apply --directory=kernel-3.18 "$f"
  git add -A
  git -c user.name=voyo-port -c user.email=port@localhost commit -q -m "$(sed -n 's/^Subject: \[PATCH[^]]*\] //p' "$f" | head -1)" -m "From android_kernel_meizu_m95 by nomorecoolnicknames."
  echo "applied $(basename "$f" | cut -c1-60)"
done

# Options the Meizu Android 13 config turns on, minus Meizu hardware.
M=~/los-kernel/m95/arch/arm64/configs/m95_defconfig
O=out/.config
for k in $(grep -E '^CONFIG_[A-Z0-9_]+=' "$M" | sed 's/=.*//;s/CONFIG_//' \
  | grep -E '^(BPF|BPF_.*|CGROUP.*|NET_CLS.*|NET_ACT.*|NETFILTER_XT_.*|IP_NF_.*|IP6_NF_.*|NF_.*|KEYS|KEY_.*|TMPFS.*|F2FS.*|EXT4.*|FS_ENCRYPTION|SECURITY.*|HARDENED.*|ARCH_MMAP_RND.*|SECCOMP.*|DUMMY|TUN|VETH|BLK_DEV_LOOP.*|OVERLAY_FS.*|FUSE.*|ZRAM.*|ZSMALLOC|CRYPTO_.*|DM_.*|PPP.*|L2TP.*|INET_DIAG.*|UNIX_DIAG|PACKET_DIAG|NETLINK_DIAG|SYN_COOKIES|USB_FUNCTIONFS|USB_CONFIGFS.*|UID_SYS_STATS|ANDROID_.*|ASHMEM|STAGING|ION|SYNC|SW_SYNC.*|MEMCG.*|POSIX_MQUEUE|AIO|EPOLL|SIGNALFD|TIMERFD|EVENTFD|FANOTIFY|INOTIFY_USER|PROFILING|PERF_EVENTS|QUOTA.*|QFMT_V2)$'); do
  if ! grep -q "^CONFIG_$k=" "$O"; then echo "$k"; fi
done > /tmp/add.txt
wc -l < /tmp/add.txt
D=arch/arm64/configs/x970_t10_97inc_defconfig
for k in $(cat /tmp/add.txt); do
  v=$(grep "^CONFIG_$k=" "$M" | cut -d= -f2-)
  sed -i "/^CONFIG_$k=/d;/^# CONFIG_$k is not set/d" $D
  echo "CONFIG_$k=$v" >> $D
done
tr '\n' ' ' < /tmp/add.txt | fold -w 100; echo
git add -A; git -c user.name=voyo-port -c user.email=port@localhost commit -q -m "x970_t10_97inc: Enable the Android 13 kernel features" || true

# 3.18 stable backported a hunk that names the struct by its later name.
sed -i 's/print_bpf_insn(const struct bpf_verifier_env \*env,/print_bpf_insn(const struct verifier_env *env,/' kernel/bpf/verifier.c
grep -q 'allow_ptr_leaks;' kernel/bpf/verifier.c || sed -i '/^struct verifier_env {/a \	bool allow_ptr_leaks;' kernel/bpf/verifier.c
for k in DM_DEBUG EXT4_DEBUG F2FS_CHECK_FS; do sed -i "/^CONFIG_$k=/d" $D; done
grep -q '^out/' .gitignore 2>/dev/null || echo 'out/' >> .gitignore
git rm -r -q --cached out 2>/dev/null || true
git add -A; git -c user.name=voyo-port -c user.email=port@localhost commit -q -m "bpf: Fix the build on 3.18.79" || true
