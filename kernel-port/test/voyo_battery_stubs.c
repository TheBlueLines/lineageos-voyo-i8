/*
 * BRING-UP ONLY. Stands in for the battery stack until the bq25890 charger
 * and the MT6351 gauge are ported, so that the first test kernel links.
 * There is no charging control in a kernel built with these.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/types.h>

void do_chrdet_int_task(void)
{
}

int set_usb_current_unlimited(bool enable)
{
	return 0;
}

int set_chr_input_current_limit(int current_limit)
{
	return 0;
}
