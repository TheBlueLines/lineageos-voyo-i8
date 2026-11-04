#!/bin/bash
ls ~/stockfs/vendor/etc/init | grep -i compos; ls ~/stockfs/vendor/bin/hw | grep -i compos; ls ~/stockfs/vendor/lib64/hw | grep -i compos
ls ~/los/hardware/interfaces/graphics/composer/2.1/default/
grep -n "name:\|cc_binary\|cc_library" ~/los/hardware/interfaces/graphics/composer/2.1/default/Android.bp
cat ~/los/hardware/interfaces/graphics/composer/2.1/default/*.rc
