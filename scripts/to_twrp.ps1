# Put the known-good TWRP back in `recovery` and boot it.
$wslRoot = "/mnt/f/Voyo i8/LineageOS"
$fb = "$wslRoot/scripts/fb.sh"
$twrp = "/mnt/f/Voyo i8/TWRP/out/twrp-3.7.0_9-voyo_i8-x970_t10_97inc.img"

adb reboot bootloader
foreach ($i in 1..20) {
    Start-Sleep -Seconds 2
    $busid = (usbipd list | Select-String '0bb4:0c01' | ForEach-Object { ($_ -split '\s+')[0] } | Select-Object -First 1)
    if ($busid) { break }
}
if (-not $busid) { throw "fastboot device did not appear" }
$attach = Start-Job -ArgumentList $busid { param($b) usbipd attach --wsl=TWRP-Builder --busid $b 2>&1 }
Wait-Job $attach -Timeout 12 | Out-Null
Stop-Job $attach -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
wsl -d TWRP-Builder -- bash $fb flash recovery $twrp 2>&1 | Select-String 'OKAY|FAILED|error' | ForEach-Object { "$_" }
wsl -d TWRP-Builder -- bash $fb oem reboot-recovery 2>&1 | Out-Null
foreach ($i in 1..12) {
    Start-Sleep -Seconds 10
    $s = (adb devices | Select-Object -Skip 1 | Out-String).Trim()
    if ($s -match '\s(device|recovery)') { "up after $($i * 10)s: $s"; break }
}
