# Flash the LineageOS images over fastboot, then boot TWRP. Usage:
# flash_los.ps1 [partitions], default boot system vendor. Run with the tablet
# in Android, TWRP or fastboot.
param([string[]]$Parts = @("boot", "system", "vendor"))
$fb = "/mnt/c/Users/David/Voyo i8/LineageOS/scripts/fb.sh"
$img = "/home/builder/los/out/target/product/x970_t10_97inc"

$mode = (adb devices | Select-Object -Skip 1 | Out-String).Trim()
if ($mode) { adb reboot bootloader }
& "C:\Users\David\Voyo i8\LineageOS\scripts\attach_fastboot.ps1"
foreach ($p in $Parts) {
    $env:WSLENV = "FB_TIMEOUT"
    $env:FB_TIMEOUT = "400"
    wsl -d TWRP-Builder -- bash $fb flash $p "$img/$p.img" 2>&1 | Select-String "OKAY|FAILED|error" | Select-Object -Last 2 | ForEach-Object { "$p $_" }
}
wsl -d TWRP-Builder -- bash $fb oem reboot-recovery 2>&1 | Out-Null
foreach ($i in 1..12) {
    Start-Sleep -Seconds 8
    $s = (adb devices | Select-Object -Skip 1 | Out-String).Trim()
    if ($s -match '\s(device|recovery)') { "up after $($i * 8)s: $s"; break }
}
