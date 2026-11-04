#!/bin/bash
# Accept the display ioctls as the stock Android 8 hwcomposer issues them. The
# stock kernel's structs are prefixes of this kernel's: disp_caps_info ends
# after lcm_degree plus 32 zero bytes (60 bytes), and disp_session_input_config
# has no ccorr_config (72 bytes shorter).
set -e
cd ~/los-kernel/gemini8/kernel-3.18
M=drivers/misc/mediatek/video/mt6797/videox/mtk_disp_mgr.c
grep -q DISP_IOCTL_GET_DISPLAY_CAPS_O $M && { echo "already patched"; exit 0; }
python3 - "$M" <<'P'
import sys
p = sys.argv[1]
s = open(p).read()


def func(head):
    start = s.index(head)
    return start, s.index("\n}\n", start) + 3


def edit(head, new_head, repl):
    global s
    a, b = func(head)
    body = s[a:b].replace(head, new_head, 1)
    for old, new in repl:
        assert body.count(old) == 1, old
        body = body.replace(old, new)
    s = s[:a] + body + s[b:]
    return a + len(body)


end = edit("int _ioctl_set_input_buffer(unsigned long arg)\n{",
           "static int __ioctl_set_input_buffer(unsigned long arg, size_t size)\n{",
           [("kmalloc(sizeof(*session_input), GFP_KERNEL)", "kzalloc(sizeof(*session_input), GFP_KERNEL)"),
            ("copy_from_user(session_input, argp, sizeof(*session_input))",
             "copy_from_user(session_input, argp, size)")])
s = s[:end] + ("\nint _ioctl_set_input_buffer(unsigned long arg)\n{\n"
               "	return __ioctl_set_input_buffer(arg, sizeof(disp_session_input_config));\n}\n") + s[end:]

end = edit("int _ioctl_get_display_caps(unsigned long arg)\n{",
           "static int __ioctl_get_display_caps(unsigned long arg, size_t size)\n{",
           [("copy_from_user(&caps_info, argp, sizeof(caps_info))", "copy_from_user(&caps_info, argp, size)"),
            ("	if (copy_to_user(argp, &caps_info, sizeof(caps_info)))",
             "	/* The stock kernel leaves everything after lcm_degree zero. */\n"
             "	if (size < sizeof(caps_info))\n"
             "		memset((char *)&caps_info + offsetof(disp_caps_info, rsz_in_res_list), 0,\n"
             "		       sizeof(caps_info) - offsetof(disp_caps_info, rsz_in_res_list));\n"
             "	if (copy_to_user(argp, &caps_info, size))")])
s = s[:end] + ("\nint _ioctl_get_display_caps(unsigned long arg)\n{\n"
               "	return __ioctl_get_display_caps(arg, sizeof(disp_caps_info));\n}\n") + s[end:]

defs = ("/* Sizes the stock Android 8 hwcomposer uses, see disp_compat_kernel.sh. */\n"
        "#define DISP_O_CAPS_SIZE	60\n"
        "#define DISP_O_INPUT_SIZE	(sizeof(disp_session_input_config) - sizeof(struct disp_ccorr_config))\n"
        "#define DISP_IOCTL_GET_DISPLAY_CAPS_O	_IOC(_IOC_WRITE, 'O', 219, DISP_O_CAPS_SIZE)\n"
        "#define DISP_IOCTL_SET_INPUT_BUFFER_O	_IOC(_IOC_WRITE, 'O', 206, DISP_O_INPUT_SIZE)\n\n")
a, _ = func("static int __ioctl_set_input_buffer(unsigned long arg, size_t size)\n{")
s = s[:a] + defs + s[a:]

old = "	case DISP_IOCTL_SET_INPUT_BUFFER:\n		{\n			return _ioctl_set_input_buffer(arg);\n		}\n"
assert s.count(old) == 1
s = s.replace(old, old +
    "	case DISP_IOCTL_SET_INPUT_BUFFER_O:\n"
    "		return __ioctl_set_input_buffer(arg, DISP_O_INPUT_SIZE);\n"
    "	case DISP_IOCTL_GET_DISPLAY_CAPS_O:\n"
    "		return __ioctl_get_display_caps(arg, DISP_O_CAPS_SIZE);\n")
open(p, "w").write(s)
P
git commit -qam "disp: accept the stock Android 8 hwcomposer's caps and input buffer ioctls" && git log --oneline -1
git show --stat HEAD | tail -2
