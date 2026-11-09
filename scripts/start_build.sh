#!/bin/bash
# Start a detached build, then wait for it. Rerunning while one runs just waits.
# Usage: start_build.sh [make targets]
L=$HOME/los
if ! pgrep -f 'build/soong/soong_ui' >/dev/null && ! pgrep -x ninja >/dev/null; then
  T=${*:-bootimage systemimage vendorimage}
  rm -f "$L/build.done"
  setsid nohup bash -c "bash '/mnt/f/Voyo i8/LineageOS/scripts/los_env.sh' m -j12 $T > '$L/build.log' 2>&1; echo \$? > '$L/build.done'" >/dev/null 2>&1 &
  sleep 20
fi
while [ ! -f "$L/build.done" ]; do sleep 30; done
echo "build exit: $(cat "$L/build.done")"
grep -E '^(FAILED|error:|ninja: error)|error: ' "$L/build.log" | cut -c1-170 | tail -n 14
tail -n 3 "$L/build.log" | cut -c1-170
