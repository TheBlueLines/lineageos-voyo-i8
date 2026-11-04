#!/system/bin/sh
# Bring-up only: log each boot to /cache.
while [ ! -d /cache/recovery ]; do sleep 0.2; done
log=/cache/voyo-diag
mkdir -p $log
# /cache is 418 MiB and filled up: keep the files of the last 8 boots.
ls -t $log | tail -n +33 | while read f; do rm -f "$log/$f"; done
n=$(cat $log/next 2>/dev/null || echo 1000)
echo $((n + 1)) > $log/next
cp /sys/fs/pstore/console-ramoops $log/pstore-$n.log 2>/dev/null
dmesg -w > $log/kmsg-$n.log 2>&1 &
logcat -b all -v threadtime -f $log/logcat-$n.log 2>/dev/null &
while :; do
    { date; getprop | grep -E 'init.svc|sys.boot_completed|ro.crypto.state'; cat /proc/uptime; } > $log/props-$n.log
    sync
    sleep 2
done
