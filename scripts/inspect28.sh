#!/bin/bash
cd ~/los/hardware/interfaces/audio/core/all-versions/default
grep -rn "mHasNougatAbi\s*=\|hasNougatAbi()\s*{\|NougatAbi\|nougat" *.cpp include/core/default/*.h Android.bp | grep -v "mDevice->hasNougatAbi() ||\|!mDevice->hasNougatAbi() &&" | head -20
