# Catch the preloader over the serial port and run an mtkclient command.
# Usage: mtk_write.ps1 <seconds> <mtk.py args...>
param([int]$Seconds = 170, [Parameter(ValueFromRemainingArguments = $true)][string[]]$MtkArgs)
$t = "C:\Users\David\Voyo i8\TWRP"
$py = "$t\tools\venv-mtk\Scripts\python.exe"
Set-Location "$t\tools\mtkclient"
$a = @("mtk.py") + ($MtkArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) + @("--serialport")
$p = Start-Process $py -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\mtkw.out" -RedirectStandardError "$env:TEMP\mtkw.err"
$d = (Get-Date).AddSeconds($Seconds)
while (-not $p.HasExited -and (Get-Date) -lt $d) { Start-Sleep -Seconds 2 }
"exited=$($p.HasExited) code=$($p.ExitCode)"
Get-Content "$env:TEMP\mtkw.out" -ErrorAction SilentlyContinue |
    Where-Object { $_ -and $_ -notmatch '^\.+$|Hint|Power off|For brom|For preloader|If it is' } |
    Select-Object -Last 14 | ForEach-Object { "$_".Substring(0, [Math]::Min(120, "$_".Length)) }
Get-Content "$env:TEMP\mtkw.err" -ErrorAction SilentlyContinue | Select-Object -Last 4
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
