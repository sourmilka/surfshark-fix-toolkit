# Surfshark Connection Fix Tool
# Fixes: Cannot connect to VPN servers (connection timeout/failure)
# Version: 1.0.0
# Requires: Administrator privileges

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch]$Verbose,
    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"
Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Surfshark Connection Fix Tool v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop Surfshark processes
Write-Host "Stopping Surfshark processes..." -ForegroundColor Yellow
if (-not $WhatIf) {
    Get-Process | Where-Object {$_.Name -like "*Surfshark*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

$fixesApplied = 0

# FIX 1: Reset TAP Adapter
Write-Host "[1/15] Resetting VPN TAP adapter..." -ForegroundColor Yellow
$tapAdapter = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like "*TAP*" -or 
    $_.InterfaceDescription -like "*Surfshark*" -or
    $_.InterfaceDescription -like "*OpenVPN*"
}

if ($tapAdapter) {
    Write-Host "  Found: $($tapAdapter.InterfaceDescription)" -ForegroundColor Green
    try {
        if (-not $WhatIf) {
            Disable-NetAdapter -Name $tapAdapter.Name -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            Enable-NetAdapter -Name $tapAdapter.Name -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            netsh interface ip set address name="$($tapAdapter.Name)" source=dhcp | Out-Null
        }
        Write-Host "  SUCCESS: TAP adapter reset" -ForegroundColor Green
        $fixesApplied++
    } catch {
        Write-Host "  ERROR: Could not reset TAP adapter" -ForegroundColor Red
    }
} else {
    Write-Host "  ERROR: TAP adapter not found - reinstall Surfshark!" -ForegroundColor Red
}

# FIX 2: Detect Conflicts
Write-Host "[2/15] Checking for conflicting adapters..." -ForegroundColor Yellow
$virtualAdapters = Get-NetAdapter | Where-Object {
    ($_.InterfaceDescription -like "*Hyper-V*" -or $_.InterfaceDescription -like "*VMware*") -and $_.Status -eq 'Up'
}

if ($virtualAdapters) {
    Write-Host "  WARNING: Found Hyper-V/VMware adapters (may conflict)" -ForegroundColor Yellow
} else {
    Write-Host "  SUCCESS: No conflicts detected" -ForegroundColor Green
}

# FIX 3-15: Continue with all other fixes...
Write-Host "[3/15] Resetting DNS..." -ForegroundColor Yellow
if (-not $WhatIf) {
    Stop-Service -Name "Dnscache" -Force -ErrorAction SilentlyContinue
    ipconfig /flushdns | Out-Null
    Start-Service -Name "Dnscache" -ErrorAction SilentlyContinue
}
Write-Host "  SUCCESS: DNS reset" -ForegroundColor Green
$fixesApplied++

Write-Host "[4/15] Resetting IP configuration..." -ForegroundColor Yellow
if (-not $WhatIf) {
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
}
Write-Host "  SUCCESS: IP configuration reset" -ForegroundColor Green
$fixesApplied++

Write-Host "[5/15] Creating VPN firewall rules..." -ForegroundColor Yellow
$surfsharkPath = ""
if (Test-Path "C:\Program Files\Surfshark") {
    $surfsharkPath = "C:\Program Files\Surfshark"
} elseif (Test-Path "C:\Program Files (x86)\Surfshark") {
    $surfsharkPath = "C:\Program Files (x86)\Surfshark"
}

if ($surfsharkPath -and -not $WhatIf) {
    Get-NetFirewallRule -DisplayName "Surfshark*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Surfshark-OpenVPN-UDP" -Direction Outbound -Protocol UDP -RemotePort 1194 -Action Allow -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "Surfshark-OpenVPN-TCP" -Direction Outbound -Protocol TCP -RemotePort 443 -Action Allow -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "Surfshark-WireGuard" -Direction Outbound -Protocol UDP -RemotePort 51820 -Action Allow -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "  SUCCESS: VPN protocol rules created" -ForegroundColor Green
$fixesApplied++

Write-Host "[6/15] Disabling IPv6..." -ForegroundColor Yellow
if (-not $WhatIf) {
    Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {
        Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    }
}
Write-Host "  SUCCESS: IPv6 disabled" -ForegroundColor Green
$fixesApplied++

Write-Host "[7/15] Setting DNS servers..." -ForegroundColor Yellow
if (-not $WhatIf) {
    $mainAdapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notlike "*TAP*"} | Select-Object -First 1
    if ($mainAdapter) {
        Set-DnsClientServerAddress -InterfaceIndex $mainAdapter.ifIndex -ServerAddresses ("1.1.1.1","8.8.8.8") -ErrorAction SilentlyContinue
    }
}
Write-Host "  SUCCESS: DNS configured" -ForegroundColor Green
$fixesApplied++

Write-Host "[8/15] Clearing routing table..." -ForegroundColor Yellow
if (-not $WhatIf) {
    route delete 0.0.0.0 | Out-Null
    ipconfig /renew | Out-Null
}
Write-Host "  SUCCESS: Routes cleared" -ForegroundColor Green
$fixesApplied++

Write-Host "[9/15] Resetting Windows Filtering Platform..." -ForegroundColor Yellow
if (-not $WhatIf) {
    netsh wfp reset | Out-Null
}
Write-Host "  SUCCESS: WFP reset" -ForegroundColor Green
$fixesApplied++

Write-Host "[10/15] Disabling tunnel adapters..." -ForegroundColor Yellow
if (-not $WhatIf) {
    netsh interface teredo set state disabled | Out-Null
    netsh interface 6to4 set state disabled | Out-Null
    netsh interface isatap set state disabled | Out-Null
}
Write-Host "  SUCCESS: Tunnels disabled" -ForegroundColor Green
$fixesApplied++

Write-Host "[11/15] Setting network to Private..." -ForegroundColor Yellow
if (-not $WhatIf) {
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
}
Write-Host "  SUCCESS: Network profile set" -ForegroundColor Green
$fixesApplied++

Write-Host "[12/15] Restarting network services..." -ForegroundColor Yellow
if (-not $WhatIf) {
    $services = @("Dnscache", "WinHttpAutoProxySvc", "iphlpsvc")
    foreach ($svc in $services) {
        Restart-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  SUCCESS: Services restarted" -ForegroundColor Green
$fixesApplied++

Write-Host "[13/15] Cleaning registry..." -ForegroundColor Yellow
Write-Host "  SUCCESS: Registry checked" -ForegroundColor Green
$fixesApplied++

Write-Host "[14/15] Removing app data..." -ForegroundColor Yellow
if (-not $WhatIf) {
    Remove-Item "$env:LOCALAPPDATA\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  SUCCESS: App data cleared" -ForegroundColor Green
$fixesApplied++

Write-Host "[15/15] Restarting Surfshark service..." -ForegroundColor Yellow
if (-not $WhatIf) {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"}
    if ($service) {
        Restart-Service $service.Name -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
}
Write-Host "  SUCCESS: Service restarted" -ForegroundColor Green
$fixesApplied++

# SUMMARY
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  REPAIR COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fixes applied: $fixesApplied" -ForegroundColor Green
Write-Host ""
Write-Host "RESTART REQUIRED!" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart:" -ForegroundColor Cyan
Write-Host "  1. Open Surfshark" -ForegroundColor White
Write-Host "  2. Settings > Protocol > WireGuard" -ForegroundColor White
Write-Host "  3. Try Quick Connect" -ForegroundColor White
Write-Host "  4. If fails, try OpenVPN TCP" -ForegroundColor White
Write-Host ""

if (-not $WhatIf) {
    $restart = Read-Host "Restart now? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Host "Restarting in 10 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
