#!/usr/bin/env python3
"""Bring-up: mirror printk into the persistent_ram console zone from
setup_arch() on, in the format the stock kernel's ramoops reads back. The
normal ramoops console starts too late to show an early hang, and this tablet
has no serial port. Run from the kernel source root. Safe to rerun."""

P = 'kernel/printk/printk.c'
S = 'arch/arm64/kernel/setup.c'

CODE = r'''
/* voyo bring-up: see kernel-port/test/early_log.py */
#include <asm/cacheflush.h>
#define VOYO_ZONE_PHYS	0x444cf000UL
#define VOYO_ZONE_SIZE	0x10000
#define VOYO_ZONE_SIG	0x43474244

struct voyo_zone {
	u32 sig;
	u32 start;
	u32 size;
	u8 data[0];
};

static struct voyo_zone *voyo_zone;

static void voyo_zone_put(const char *s, unsigned int n)
{
	struct voyo_zone *z = voyo_zone;
	unsigned int max = VOYO_ZONE_SIZE - sizeof(*z);

	if (!z)
		return;
	while (n) {
		unsigned int c = min(n, max - z->start);

		memcpy(z->data + z->start, s, c);
		__flush_dcache_area(z->data + z->start, c);
		z->start = (z->start + c) % max;
		z->size = min(z->size + c, max);
		s += c;
		n -= c;
	}
	__flush_dcache_area(z, sizeof(*z));
}

'''

START = r'''
void voyo_early_log_start(void)
{
	u32 idx = log_first_idx;
	u64 seq = log_first_seq;

	voyo_zone = phys_to_virt(VOYO_ZONE_PHYS);
	voyo_zone->sig = VOYO_ZONE_SIG;
	voyo_zone->start = 0;
	voyo_zone->size = 0;
	while (seq < log_next_seq) {
		struct printk_log *msg = log_from_idx(idx);

		voyo_zone_put(log_text(msg), msg->text_len);
		voyo_zone_put("\n", 1);
		idx = log_next(idx);
		seq++;
	}
}
'''

TEE = ('\tvoyo_zone_put(log_text(msg), msg->text_len);\n'
       '\tvoyo_zone_put("\\n", 1);\n')

s = open(P, errors='surrogateescape').read()
i = s.find('#ifdef CONFIG_PSTORE\n\t{\t/* voyo bring-up */')
if i >= 0:
    s = s[:i] + s[s.index('#endif\n', i) + 7:]
if 'voyo_zone_put' not in s:
    tag = '/* insert record into the buffer, discard old ones, update heads */\n'
    if tag not in s:
        tag = 'static int log_store(int facility'
    s = s.replace(tag, CODE + tag, 1)
    ret = '\treturn msg->text_len;\n'
    assert s.count(ret) == 1
    s = s.replace(ret, TEE + ret)
    tag = '\n/* /dev/kmsg - userspace message inject/listen interface */'
    assert tag in s
    s = s.replace(tag, START + tag, 1)
open(P, 'w', errors='surrogateescape').write(s)

s = open(S, errors='surrogateescape').read()
if 'voyo_early_log_start' not in s:
    tag = '\tpaging_init();\n'
    assert s.count(tag) == 1
    s = s.replace(tag, tag + '\t{\n\t\textern void voyo_early_log_start(void);\n\n'
                  '\t\tvoyo_early_log_start();\n\t}\n')
    open(S, 'w', errors='surrogateescape').write(s)
