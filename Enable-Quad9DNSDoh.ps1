#requires -RunAsAdministrator

Set-StrictMode -Version 3

#
# This script configures Quad9 as secure DNS provider in Windows 11.
#
# Inspiration: https://help.nextdns.io/t/60hj3yd/enable-doh-natively-on-windows-11
#

# User-configurable
$ipv4a = "9.9.9.9"
$ipv4b = "149.112.112.112"
$ipv6a = "2620:fe::fe"
$ipv6b = "2620:fe::9"

# Build the DoH query template (malware blocking, DNSSEC validation)
$template = "https://dns.quad9.net/dns-query"

# Remove existing DoH entries (there is no cmdlet to create *and/or* update entries)
Write-Host "DoH servers: $ipv4a, $ipv4b, $ipv6a, $ipv6b"
Write-Host "Removing previously configured settings for DoH servers..." -ForegroundColor Green
Remove-DnsClientDohServerAddress -ServerAddress $ipv4a, $ipv4b, $ipv6a, $ipv6b -Erroraction Ignore | Out-Null

# Add new DoH entries
Write-Host "Adding settings for DoH servers..." -ForegroundColor Green
Add-DnsClientDohServerAddress -ServerAddress $ipv4a -DohTemplate $template -AllowFallbackToUdp $False -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress $ipv4b -DohTemplate $template -AllowFallbackToUdp $False -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress $ipv6a -DohTemplate $template -AllowFallbackToUdp $False -AutoUpgrade $True
Add-DnsClientDohServerAddress -ServerAddress $ipv6b -DohTemplate $template -AllowFallbackToUdp $False -AutoUpgrade $True

Write-Host "Setting DoH DNS servers on network interfaces..." -ForegroundColor Green

# Enumerate Wi-Fi and Ethernet interfaces
$interfaces = Get-NetIPConfiguration | Where-Object InterfaceAlias -match "^Wi-Fi|^Ethernet"
foreach ($interace in $interfaces)
{
   # Set the configured DoH addresses as DNS servers
   Set-DnsClientServerAddress -InterfaceIndex ($interace).InterfaceIndex -ServerAddresses $ipv4a, $ipv4b, $ipv6a, $ipv6b

   #
   # Add a last crucial registry value that the cmdlets as well as netsh.exe are missing
   # Without this, the newly added servers show up as unencrypted in the settings UI
   #

   # Get the network interface GUID
   $interfaceId = $interace.NetAdapter.DeviceID

   # Build the registry paths to the interface's DoH settings
   $regpathbase  = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters"
   $regpathipv4  = "$regpathbase\$interfaceId\DohInterfaceSettings\Doh"
   $regpathipv6  = "$regpathbase\$interfaceId\DohInterfaceSettings\Doh6"
   $regpaths     = @()
   $regpaths     += "$regpathipv4\$ipv4a"
   $regpaths     += "$regpathipv4\$ipv4b"
   $regpaths     += "$regpathipv6\$ipv6a"
   $regpaths     += "$regpathipv6\$ipv6b"

   # Process each registry key (IPv4/IPv6 primary/alternate DNS server)
   foreach ($regpath in $regpaths)
   {
      if (-not (Test-Path $regpath))
      {
         # Registry key does not exist yet -> create
         New-Item -Path $regpath -Force | Out-Null
      }

      # Add the crucial missing registry value
      New-ItemProperty -Path $regpath -Name "DohFlags" -Value 1 -PropertyType QWORD -Force | Out-Null
   }
} 