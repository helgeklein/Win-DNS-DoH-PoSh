# Win-DNS-DoH-PoSh

This repository contains a set of PowerShell scripts to configure Windows 11 DNS over HTTPS (DoH) for NextDNS, Quad9 and (potentially) other providers. There is also a script to reset DNS settings to the default (unencrypted) state, which can sometimes be necessary when authenticating on a captive portal (e.g., Deutsche Bahn's WiFiOnIce) or when local name resolution is required (e.g., when accessing `fritz.box`).

## Scripts

### Enable-NextDNSDoh.ps1

This script configures NextDNS as secure DNS provider in Windows 11.

### Enable-Quad9DNSDoh.ps1

This script configures Quad9 as secure DNS provider in Windows 11.

### Reset-DnsToDhcp.ps1

This script resets DNS servers to what is configured via DHCP.

## Implementation Notes

### PowerShell and NetSh Fail to Enable Encrytion

The relevant PowerShell cmdlets for working with DoH can be found on many websites, including [Microsoft's documentation](https://docs.microsoft.com/en-us/powershell/module/dnsclient/add-dnsclientdohserveraddress?view=windowsserver2022-ps). What all sources fail to mention is that PowerShell (or `netsh`, for that matter), is not enough. An additional registry value needs to be set manually that no command-line tool currently takes care of. Without that value, DoH encryption remains disabled, as can be verified in the Settings UI.

The missing registry value to actually enable DNS-over-HTTS encryption for **IPv4**:

    Registry path:  HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{INTERFACE-ID}\DohInterfaceSettings\Doh\{IP-ADDRESS}
    Registry value: DohFlags
    Value type:     QWORD
    Data:           1

The missing registry value to actually enable DNS-over-HTTS encryption for **IPv6**:

    Registry path:  HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\{INTERFACE-ID}\DohInterfaceSettings\Doh6\{IP-ADDRESS}
    Registry value: DohFlags
    Value type:     QWORD
    Data:           1
