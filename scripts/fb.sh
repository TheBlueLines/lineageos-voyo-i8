#!/bin/bash
# Run fastboot in WSL, as root if needed for the USB device node.
F=/usr/bin/fastboot
if sudo -n true 2>/dev/null; then F="sudo -n $F"; fi
exec timeout "${FB_TIMEOUT:-60}" $F "$@"
