# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# References:
# https://medium.com/@cosmin.ciobanu/enhanced-endpoint-detection-using-sysmon-and-wef-3b65d491ff95

[CmdletBinding()]
param (
    [string]$SysmonConfigUrl = "https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/configs/sysmon/sysmon.xml"
)

write-host "[+] Processing Sysmon Installation.."

$URL = "https://live.sysinternals.com/Sysmon.exe"
Resolve-DnsName live.sysinternals.com
Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com

$OutputFile = Split-Path $Url -leaf
$File = "C:\ProgramData\$OutputFile"

# Download File
write-Host "[+] Downloading $OutputFile .."
$wc = new-object System.Net.WebClient
$wc.DownloadFile($Url, $File)
if (!(Test-Path $File)) { Write-Error "File $File does not exist" -ErrorAction Stop }

# Downloading Sysmon Configuration
write-Host "[+] Downloading Sysmon config.."
$SysmonFile = "C:\ProgramData\sysmon.xml"
$wc.DownloadFile($SysmonConfigUrl, $SysmonFile)
if (!(Test-Path $SysmonFile)) { Write-Error "File $SysmonFile does not exist" -ErrorAction Stop }

# Installing Sysmon
write-Host "[+] Installing Sysmon.."
& $File -i C:\ProgramData\sysmon.xml -accepteula

write-Host "[+] Setting Sysmon to start automatically.."
& sc.exe config Sysmon start= auto

# Setting Sysmon Channel Access permissions
write-Host "[+] Setting up Channel Access permissions for Microsoft-Windows-Sysmon/Operational "
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Sysmon/Operational" -Name "ChannelAccess" -PropertyType String -Value "O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)" -Force

write-Host "[+] Restarting Log Services .."
$LogServices = @("Sysmon", "Windows Event Log")

# Restarting Log Services
foreach ($LogService in $LogServices)
{
    write-Host "[+] Restarting $LogService .."
    Restart-Service -Name $LogService -Force

    write-Host "  [*] Verifying if $LogService is running.."
    $s = Get-Service -Name $LogService
    while ($s.Status -ne 'Running') { Start-Service $LogService; Start-Sleep 3 }
    Start-Sleep 5
    write-Host "  [*] $LogService is running.."
}