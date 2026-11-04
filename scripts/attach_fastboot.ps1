# Attach the tablet's fastboot interface to WSL, waiting until it is visible there.
foreach ($i in 1..30) {
    $line = usbipd list | Select-String '0bb4:0c01' | Select-Object -First 1
    if ($line) { break }
    Start-Sleep -Seconds 2
}
if (-not $line) { throw "fastboot device did not appear" }
$busid = ("$line".Trim() -split '\s+')[0]
foreach ($try in 1..4) {
    if ("$(usbipd list | Select-String '0bb4:0c01')" -notmatch 'Attached') {
        Start-Process usbipd -ArgumentList "attach --wsl=TWRP-Builder --busid $busid" -NoNewWindow -Wait `
            -RedirectStandardError "$env:TEMP\usbipd.err" -RedirectStandardOutput "$env:TEMP\usbipd.out"
    }
    foreach ($i in 1..5) {
        Start-Sleep -Seconds 2
        $seen = wsl -d TWRP-Builder -- bash -c "lsusb | grep -c '0bb4:0c01'"
        if ("$seen".Trim() -ne '0') { "attached ($busid)"; return }
    }
}
throw "fastboot device did not reach WSL"
