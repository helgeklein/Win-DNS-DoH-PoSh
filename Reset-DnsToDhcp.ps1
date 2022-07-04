#requires -RunAsAdministrator

Set-StrictMode -Version 3

#
# This script resets DNS servers to what is configured via DHCP.
#

Write-Host "resetting DNS servers on network interfaces..." -ForegroundColor Green

$interfaces = Get-NetIPConfiguration | Where-Object InterfaceAlias -match "^Wi-Fi|^Ethernet"
foreach ($index in ($interfaces).InterfaceIndex)
{
   Set-DnsClientServerAddress -InterfaceIndex $index -ResetServerAddresses
} 