#!/bin/bash
F=~/los/out/target/product/x970_t10_97inc/vendor/lib64/hw/hwcomposer.mt6797.so
strings -n 6 $F | grep -E "^(persist\.|debug\.|vendor\.|ro\.)" | head -40
strings -n 6 $F | grep -nE "loglevel|LogLevel|log level" | head
