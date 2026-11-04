# From TWRP: copy built images to the SD card, flash them from there and verify.
# Usage: flash_sd.ps1 [boot] [vendor] [system]
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Parts = @("boot", "vendor"))
$W = '\\wsl.localhost\TWRP-Builder\home\builder\los\out\target\product\x970_t10_97inc'
$blk = @{ boot = "mmcblk0p23"; vendor = "mmcblk0p29"; system = "mmcblk0p30" }
foreach ($p in $Parts) {
    adb push "$W\$p.img" "/external_sd/LineageOS/$p.img" 2>&1 | Select-Object -Last 1
    if ($p -eq "boot") {
        adb shell "cd /external_sd/LineageOS && dd if=boot.img of=/dev/block/$($blk[$p]) bs=1048576 2>/dev/null && sync && echo 3 > /proc/sys/vm/drop_caches && n=`$(stat -c %s boot.img) && echo boot img `$(sha256sum boot.img | cut -c1-16) part `$(dd if=/dev/block/$($blk[$p]) bs=512 count=`$((n/512)) 2>/dev/null | sha256sum | cut -c1-16)"
    } else {
        # simg2img straight to the partition skips empty chunks; expand in RAM first.
        adb shell "simg2img /external_sd/LineageOS/$p.img /tmp/$p.raw && dd if=/tmp/$p.raw of=/dev/block/$($blk[$p]) bs=1048576 2>/dev/null; sync; echo 3 > /proc/sys/vm/drop_caches; echo $p raw `$(sha256sum /tmp/$p.raw | cut -c1-16) part `$(sha256sum /dev/block/$($blk[$p]) | cut -c1-16); rm /tmp/$p.raw"
    }
}
adb shell "cd /external_sd/LineageOS && sha256sum *.img > SHA256SUMS"
