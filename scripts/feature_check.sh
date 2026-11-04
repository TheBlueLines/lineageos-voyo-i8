#!/bin/bash
# Which Android 13 kernel features does the Gemini tree already have?
cd ~/los-kernel/gemini8/kernel-3.18
c() { # label file-pattern text
  if grep -rqs -- "$3" $2 2>/dev/null; then echo "HAVE  $1"; else echo "MISS  $1"; fi
}
c 'binder_alloc (new binder)'    'drivers/android drivers/staging/android' 'binder_alloc_'
c 'binder IPC 8-byte'            '.' 'CONFIG_ANDROID_BINDER_IPC_32BIT'
c 'sdcardfs'                     'fs/sdcardfs/Makefile' 'sdcardfs'
c 'sdcardfs Android P (gid derive)' 'fs/sdcardfs/sdcardfs.h' 'data_app'
c 'per-mount perm hooks'         'include/linux/fs.h' 'permission2'
c 'ambient capabilities'         'include/uapi/linux/prctl.h' 'PR_CAP_AMBIENT'
c 'SOCK_DESTROY'                 'net/core/sock_diag.c' 'sock_diag_destroy'
c 'hardened usercopy'            'security/Kconfig' 'HARDENED_USERCOPY'
c 'ARCH_MMAP_RND_BITS'           'arch/Kconfig' 'ARCH_MMAP_RND_BITS'
c 'SELinux xperms policy'        'security/selinux/include/security.h' 'POLICYDB_VERSION_XPERMS_IOCTL'
c 'perf_event restrict'          'security/Kconfig' 'SECURITY_PERF_EVENTS_RESTRICT'
c 'uid_sys_stats'                'drivers/misc/Kconfig' 'UID_SYS_STATS'
c 'eBPF syscall'                 'kernel/bpf/syscall.c' 'SYSCALL_DEFINE3(bpf'
c 'xt_bpf'                       'net/netfilter/Kconfig' 'NETFILTER_XT_MATCH_BPF'
c 'f2fs'                         'fs/f2fs/Makefile' 'f2fs'
c 'ext4 encryption'              'fs/ext4/Kconfig' 'EXT4_ENCRYPTION'
c 'memcg'                        'mm/memcontrol.c' 'mem_cgroup'
c 'overlayfs'                    'fs/overlayfs/Makefile' 'overlay'
c 'psi'                          'kernel/sched/psi.c' 'psi'
c 'memfd_create'                 'mm/shmem.c' 'SYSCALL_DEFINE2(memfd_create'
c 'getrandom'                    'drivers/char/random.c' 'SYSCALL_DEFINE3(getrandom'
c 'renameat2'                    'fs/namei.c' 'SYSCALL_DEFINE5(renameat2'
c 'seccomp TSYNC'                'kernel/seccomp.c' 'SECCOMP_FILTER_FLAG_TSYNC'
c 'FunctionFS AIO'               'drivers/usb/gadget/function/f_fs.c' 'ffs_epfile_aio_write\|write_iter'
c 'pidfd etc skipped'             'kernel/fork.c' 'clone'
c 'configfs usb gadget'          'drivers/usb/gadget/Kconfig' 'USB_CONFIGFS'
c 'dm-verity FEC'                'drivers/md/Kconfig' 'DM_VERITY_FEC'
echo; grep -E '^(# )?CONFIG_(BPF_SYSCALL|BPF_JIT|CGROUP_BPF|KEYS|MEMCG|TMPFS_XATTR|TMPFS_POSIX_ACL|F2FS_FS|EXT4_FS_SECURITY|NETFILTER_XT_MATCH_QTAGUID|NETFILTER_XT_MATCH_OWNER|ANDROID_BINDER_DEVICES|SDCARD_FS|FUSE_FS|QFMT_V2|QUOTA|CGROUP_SCHED|DUMMY|IP6_NF_RAW|BLK_DEV_LOOP|DM_VERITY)( |=)' out/.config | cut -c1-70
