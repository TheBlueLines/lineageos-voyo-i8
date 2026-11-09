# Flash out/test-recovery.img, boot it, wait for the fallback boot of the
# diagnostic stock image, and save what it kept. Usage: test_cycle.ps1 <run-id>
param([string]$Run = "x")
$root = "F:\Voyo i8\LineageOS"
$wslRoot = "/mnt/f/Voyo i8/LineageOS"
$fb = "$wslRoot/scripts/fb.sh"

adb reboot bootloader
& "$root\scripts\attach_fastboot.ps1"
wsl -d TWRP-Builder -- bash $fb flash recovery "$wslRoot/out/test-recovery.img" 2>&1 | Select-String 'OKAY|FAILED|error' | ForEach-Object { "$_" }
wsl -d TWRP-Builder -- bash $fb oem reboot-recovery 2>&1 | Out-Null

foreach ($i in 1..18) {
    Start-Sleep -Seconds 10
    $s = (adb devices | Select-Object -Skip 1 | Out-String).Trim()
    if ($s -match '\s(device|recovery)') { "up after $($i * 10)s: $s"; break }
}
if (-not ($s -match '\s(device|recovery)')) { "no adb after 180s"; return }
adb shell "uname -v; getprop ro.boot.mode; getprop ro.twrp.version"
if ($s -match 'recovery') { "TEST KERNEL IS UP"; return }
foreach ($i in 1..12) {
    if ((adb shell getprop sys.boot_completed).Trim() -eq '1') { break }
    Start-Sleep -Seconds 5
}
Start-Sleep -Seconds 4
cmd /c "adb exec-out cat /data/anr/voyo-pstore > `"$root\device-info\pstore-$Run.txt`" 2>nul"
cmd /c "adb exec-out cat /data/anr/voyo-expdb.bin > `"$root\device-info\expdb-$Run.bin`" 2>nul"
(Get-Item "$root\device-info\pstore-$Run.txt").Length
