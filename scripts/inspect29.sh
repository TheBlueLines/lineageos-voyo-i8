#!/bin/bash
cd ~/los/hardware/interfaces
git log --oneline -3 -- audio/core/all-versions/default/PrimaryDevice.cpp
git status --short audio | head
cd audio/core/all-versions/default
sed -n 30,60p PrimaryDevice.cpp
grep -n "hasNougatAbi\|mHasNougatAbi" include/core/default/Device.h
grep -rn "hasNougatAbi\|legacy_nougat_abi" DevicesFactory.cpp | head
