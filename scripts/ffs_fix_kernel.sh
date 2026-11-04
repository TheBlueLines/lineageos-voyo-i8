#!/bin/bash
# FunctionFS AIO reads copy to user memory from a kworker, which runs with
# KERNEL_DS. This arm64 kernel oopses on that ("Accessing user space memory
# with fs=KERNEL_DS"), so every adb shell crashed the tablet. Switch to USER_DS
# for the copy, as later kernels do.
set -e
cd ~/los-kernel/gemini8/kernel-3.18
F=drivers/usb/gadget/function/f_fs.c
grep -q "oldfs = get_fs()" $F && { echo "already patched"; exit 0; }
python3 - "$F" <<'P'
import sys
p = sys.argv[1]
s = open(p).read()
old = """		ret = min_t(int, ret, io_data->len);

		use_mm(io_data->mm);
"""
new = """		mm_segment_t oldfs = get_fs();

		ret = min_t(int, ret, io_data->len);

		set_fs(USER_DS);
		use_mm(io_data->mm);
"""
assert s.count(old) == 1
s = s.replace(old, new)
old2 = """		unuse_mm(io_data->mm);
	}

	aio_complete(io_data->kiocb, ret, ret);"""
assert s.count(old2) == 1
s = s.replace(old2, """		unuse_mm(io_data->mm);
		set_fs(oldfs);
	}

	aio_complete(io_data->kiocb, ret, ret);""")
open(p, "w").write(s)
P
grep -q "linux/uaccess.h" $F || sed -i '0,/#include <linux\/uio.h>/s//#include <linux\/uio.h>\n#include <linux\/uaccess.h>/' $F
git commit -qam "usb: f_fs: use USER_DS when copying AIO reads from the worker" && git log --oneline -1
