# Wait for the wedged DA's COM port to drop (someone held the power button),
# then write TWRP to boot as soon as the preloader comes back.
$deadline = (Get-Date).AddMinutes(115)
function Port { Get-CimInstance Win32_PnPEntity | Where-Object { $_.DeviceID -match 'VID_0E8D&PID_200[01]' } }
while ((Port) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 1 }
if (Port) { "no reset seen"; return }
"reset seen at $(Get-Date)"
& "F:\Voyo i8\LineageOS\scripts\mtk_write.ps1" 900 w boot "F:\Voyo i8\TWRP\out\twrp-3.7.0_9-voyo_i8-x970_t10_97inc.img"
