# Wait for TWRP, then pull the logs of the boot before it. Usage: wait_twrp_logs.ps1 <run-id>
param([string]$Run = "x", [int]$Minutes = 115)
$r = "F:\Voyo i8\LineageOS\device-info"
$deadline = (Get-Date).AddMinutes($Minutes)
do {
    Start-Sleep -Seconds 3
    $s = (adb devices | Select-Object -Skip 1 | Out-String).Trim()
} until ($s -match '\srecovery' -or (Get-Date) -gt $deadline)
if ($s -notmatch '\srecovery') { "no TWRP within $Minutes minutes"; return }
"TWRP up at $(Get-Date)"
adb shell "getprop ro.bootmode; ls -la /sys/fs/pstore; ls -la /cache/voyo-diag; cat /sys/class/power_supply/battery/batt_vol; cat /sys/class/power_supply/battery/capacity"
cmd /c "adb exec-out cat /sys/fs/pstore/console-ramoops > `"$r\pstore-$Run.txt`" 2>nul"
cmd /c "adb exec-out cat /sys/fs/pstore/console-ramoops-2 > `"$r\pstore-$Run-2.txt`" 2>nul"
cmd /c "adb exec-out dd if=/dev/block/mmcblk0p3 bs=1048576 2>nul > `"$r\expdb-$Run.bin`""
Get-Item "$r\pstore-$Run.txt", "$r\pstore-$Run-2.txt", "$r\expdb-$Run.bin" | ForEach-Object { "$($_.Name) $($_.Length)" }
# The logger in vendor writes here; also let adb in without the on-screen prompt.
adb shell "mount /cache 2>/dev/null; ls -la /cache/voyo-diag"
adb pull /cache/voyo-diag "$r\diag-$Run" 2>&1 | Select-Object -Last 1
adb shell "mount /data 2>/dev/null; mkdir -p /data/misc/adb"
adb push "$env:USERPROFILE\.android\adbkey.pub" /data/misc/adb/adb_keys 2>&1 | Select-Object -Last 1
adb shell "chown 1000:2000 /data/misc/adb/adb_keys; chmod 640 /data/misc/adb/adb_keys; chcon u:object_r:adb_keys_file:s0 /data/misc/adb/adb_keys; ls -lZ /data/misc/adb"
