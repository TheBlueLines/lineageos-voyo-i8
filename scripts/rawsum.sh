#!/bin/bash
# Checksums of the built images as they will sit on the partitions.
cd ~/los/out/target/product/x970_t10_97inc
sha256sum boot.img; stat -c "boot size %s" boot.img
~/los/out/host/linux-x86/bin/simg2img vendor.img /tmp/vendor.raw && sha256sum /tmp/vendor.raw && stat -c "vendor raw %s" /tmp/vendor.raw; rm -f /tmp/vendor.raw
