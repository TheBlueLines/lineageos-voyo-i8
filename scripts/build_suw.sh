#!/bin/bash
# Rebuild Settings and LineageSetupWizard (setupcompat users). Log: ~/build_suw.log
bash "/mnt/f/Voyo i8/LineageOS/scripts/los_env.sh" m Settings LineageSetupWizard
echo BUILD_EXIT=$?
