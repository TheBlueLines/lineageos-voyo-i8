#!/bin/bash
# Copy the built Android 13 platform policy next to the stock O policy, for
# tools/port_stock_sepolicy.py.
set -e
P=$HOME/los/out/target/product/x970_t10_97inc
D='/mnt/f/Voyo i8/LineageOS/out/selinux/a13'
mkdir -p "$D"
cp $P/system/etc/selinux/plat_sepolicy.cil $P/system/etc/selinux/plat_file_contexts \
   $P/system/etc/selinux/plat_property_contexts $P/system/etc/selinux/plat_hwservice_contexts \
   $P/system/etc/selinux/plat_service_contexts $P/vendor/etc/selinux/plat_pub_versioned.cil \
   $P/vendor/etc/selinux/vendor_sepolicy.cil "$D/"
cp $HOME/los/system/sepolicy/private/genfs_contexts "$D/plat_genfs_contexts"
ls $P/system/system_ext/etc/selinux 2>/dev/null || true
