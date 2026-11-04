# Flash images, boot LineageOS, and collect what happened.
# Usage: los_cycle.ps1 <run-id> [partitions]. Tablet in TWRP, Android or fastboot.
param([string]$Run = "x", [string[]]$Parts = @("boot"), [int]$Wait = 300)
$root = "C:\Users\David\Voyo i8\LineageOS"
$fb = "/mnt/c/Users/David/Voyo i8/LineageOS/scripts/fb.sh"

& "$root\scripts\flash_los.ps1" $Parts 2>&1 | Select-Object -Last 6
adb shell reboot
$t = 0
do {
    Start-Sleep -Seconds 10; $t += 10
    $s = (adb devices | Select-Object -Skip 1 | Out-String).Trim()
    $fastboot = usbipd list | Select-String '0bb4:0c01'
} until ($s -match '\s(device|recovery)' -or $fastboot -or $t -ge $Wait)
"after ${t}s adb='$s' fastboot=$([bool]$fastboot)"
if ($fastboot) {
    & "$root\scripts\attach_fastboot.ps1"
    wsl -d TWRP-Builder -- bash $fb oem reboot-recovery 2>&1 | Out-Null
    foreach ($i in 1..10) {
        Start-Sleep -Seconds 6
        $s = (adb devices | Select-Object -Skip 1 | Out-String).Trim()
        if ($s -match '\s(device|recovery)') { break }
    }
}
adb shell "getprop ro.twrp.version; getprop ro.lineage.version; getprop ro.build.version.release; uname -r"
if ($s -match 'recovery') {
    cmd /c "adb exec-out cat /sys/fs/pstore/console-ramoops > `"$root\device-info\pstore-$Run.txt`" 2>nul"
    (Get-Item "$root\device-info\pstore-$Run.txt").Length
}
