#!/bin/bash
# Turn off MTK's lock debugging and RT group scheduling. With PROVE_LOCKING every
# rt_rq takes a slot in a fixed per-CPU table (MAX_SPIN_KEY in kernel/sched/rt.c),
# and Android 13 creates enough cpu cgroups to overflow it: BUG in init_rt_rq().
# Android kernels leave RT_GROUP_SCHED off anyway.
cd ~/los-kernel/gemini8/kernel-3.18
D=arch/arm64/configs/x970_t10_97inc_defconfig
for k in RT_GROUP_SCHED PROVE_LOCKING DEBUG_LOCK_ALLOC LOCK_STAT LOCKDEP DEBUG_LOCKDEP \
         DEBUG_SPINLOCK DEBUG_MUTEXES DEBUG_ATOMIC_SLEEP PROVE_RCU; do
  sed -i "/^CONFIG_$k=/d;/^# CONFIG_$k is not set/d" $D
  echo "# CONFIG_$k is not set" >> $D
done
git add -A >/dev/null 2>&1; git commit -qm "defconfig: disable lock debugging and RT group scheduling" && git log --oneline -1
