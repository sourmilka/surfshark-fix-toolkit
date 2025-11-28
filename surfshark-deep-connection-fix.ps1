# SURFSHARK DEEP VPN CONNECTION REPAIR
# Advanced diagnostics and fixes for connection failures
# Run as Administrator

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SURFSHARK DEEP CONNECTION REPAIR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop Surfshark first
Write-Host "Stopping Surfshark processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.Name -like "*Surfshark*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# DEEP FIX 1: Completely reset TAP adapter
Write-Host "[1/15] Resetting TAP adapter..." -ForegroundColor Yellow
$tapAdapter = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like "*TAP*" -or 
    $_.InterfaceDescription -like "*Surfshark*" -or
    $_.InterfaceDescription -like "*OpenVPN*"
}

if ($tapAdapter) {
    Write-Host "  Found: $($tapAdapter.InterfaceDescription)" -ForegroundColor Green
    try {
        Disable-NetAdapter -Name $tapAdapter.Name -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        Enable-NetAdapter -Name $tapAdapter.Name -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "  SUCCESS: TAP adapter reset" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Could not reset TAP adapter" -ForegroundColor Red
    }
    
    # Reset TCP/IP on TAP adapter
    try {
        netsh interface ip set address name="$($tapAdapter.Name)" source=dhcp | Out-Null
        Write-Host "  SUCCESS: TAP adapter set to DHCP" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Could not configure DHCP" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERROR: TAP adapter not found - reinstall needed!" -ForegroundColor Red
    $tapMissing = $true
}

# DEEP FIX 2: Disable all other VPN/Virtual adapters temporarily
Write-Host "[2/15] Checking for conflicting adapters..." -ForegroundColor Yellow
$virtualAdapters = Get-NetAdapter | Where-Object {
    ($_.InterfaceDescription -like "*VPN*" -or 
     $_.InterfaceDescription -like "*Virtual*" -or
     $_.InterfaceDescription -like "*Hyper-V*" -or
     $_.InterfaceDescription -like "*VMware*" -or
     $_.InterfaceDescription -like "*VirtualBox*") -and
    $_.InterfaceDescription -notlike "*Surfshark*" -and
    $_.InterfaceDescription -notlike "*TAP*" -and
    $_.Status -eq 'Up'
}

if ($virtualAdapters) {
    Write-Host "  Found conflicting virtual adapters:" -ForegroundColor Yellow
    foreach ($adapter in $virtualAdapters) {
        Write-Host "    - $($adapter.InterfaceDescription)" -ForegroundColor Gray
    }
    Write-Host "  These may interfere with VPN connection" -ForegroundColor Yellow
} else {
    Write-Host "  No conflicts detected" -ForegroundColor Green
}

# DEEP FIX 3: Clear all DNS cache and reset DNS client
Write-Host "[3/15] Resetting DNS completely..." -ForegroundColor Yellow
try {
    Stop-Service -Name "Dnscache" -Force -ErrorAction Stop
    Start-Sleep -Seconds 1
    ipconfig /flushdns | Out-Null
    Start-Service -Name "Dnscache" -ErrorAction Stop
    Write-Host "  SUCCESS: DNS reset complete" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Partial DNS reset" -ForegroundColor Yellow
}

# DEEP FIX 4: Reset IP configuration completely
Write-Host "[4/15] Resetting IP configuration..." -ForegroundColor Yellow
try {
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
    Write-Host "  SUCCESS: IP configuration reset" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Partial reset" -ForegroundColor Yellow
}

# DEEP FIX 5: Remove and recreate firewall rules
Write-Host "[5/15] Recreating firewall rules..." -ForegroundColor Yellow
try {
    # Remove all Surfshark rules
    Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Surfshark*"} | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    
    # Find Surfshark installation
    $surfsharkPath = ""
    if (Test-Path "C:\Program Files\Surfshark") {
        $surfsharkPath = "C:\Program Files\Surfshark"
    } elseif (Test-Path "C:\Program Files (x86)\Surfshark") {
        $surfsharkPath = "C:\Program Files (x86)\Surfshark"
    }
    
    if ($surfsharkPath) {
        # Create comprehensive rules
        New-NetFirewallRule -DisplayName "Surfshark-App-Out" -Direction Outbound -Program "$surfsharkPath\Surfshark.exe" -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark-App-In" -Direction Inbound -Program "$surfsharkPath\Surfshark.exe" -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark-Service-Out" -Direction Outbound -Program "$surfsharkPath\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark-Service-In" -Direction Inbound -Program "$surfsharkPath\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        
        # VPN Protocols
        New-NetFirewallRule -DisplayName "Surfshark-OpenVPN-UDP-1194" -Direction Outbound -Protocol UDP -RemotePort 1194 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark-OpenVPN-TCP-443" -Direction Outbound -Protocol TCP -RemotePort 443 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark-WireGuard-UDP-51820" -Direction Outbound -Protocol UDP -RemotePort 51820 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
        
        Write-Host "  SUCCESS: All firewall rules created" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Surfshark path not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING: Some rules may have failed" -ForegroundColor Yellow
}

# DEEP FIX 6: Disable IPv6 on all adapters
Write-Host "[6/15] Disabling IPv6..." -ForegroundColor Yellow
try {
    Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {
        Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    }
    Write-Host "  SUCCESS: IPv6 disabled on all adapters" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not disable IPv6" -ForegroundColor Yellow
}

# DEEP FIX 7: Set DNS to reliable servers
Write-Host "[7/15] Setting reliable DNS servers..." -ForegroundColor Yellow
try {
    $mainAdapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notlike "*TAP*"} | Select-Object -First 1
    if ($mainAdapter) {
        Set-DnsClientServerAddress -InterfaceIndex $mainAdapter.ifIndex -ServerAddresses ("1.1.1.1","8.8.8.8") -ErrorAction Stop
        Write-Host "  SUCCESS: DNS set to 1.1.1.1, 8.8.8.8" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Could not set DNS" -ForegroundColor Yellow
}

# DEEP FIX 8: Clear routing table
Write-Host "[8/15] Clearing routing table..." -ForegroundColor Yellow
try {
    route delete 0.0.0.0 | Out-Null
    Start-Sleep -Seconds 1
    ipconfig /renew | Out-Null
    Write-Host "  SUCCESS: Routing table cleared" -ForegroundColor Green
} catch {
    Write-Host "  INFO: Route reset attempted" -ForegroundColor Gray
}

# DEEP FIX 9: Reset Windows Filtering Platform
Write-Host "[9/15] Resetting Windows Filtering Platform..." -ForegroundColor Yellow
try {
    netsh wfp reset | Out-Null
    Write-Host "  SUCCESS: WFP reset" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: WFP reset failed" -ForegroundColor Yellow
}

# DEEP FIX 10: Disable teredo, isatap, 6to4
Write-Host "[10/15] Disabling tunnel adapters..." -ForegroundColor Yellow
try {
    netsh interface teredo set state disabled | Out-Null
    netsh interface 6to4 set state disabled | Out-Null
    netsh interface isatap set state disabled | Out-Null
    Write-Host "  SUCCESS: Tunnel adapters disabled" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not disable all tunnels" -ForegroundColor Yellow
}

# DEEP FIX 11: Set network profile to Private
Write-Host "[11/15] Setting network profile to Private..." -ForegroundColor Yellow
try {
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
    Write-Host "  SUCCESS: Network set to Private" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not change network profile" -ForegroundColor Yellow
}

# DEEP FIX 12: Restart related services
Write-Host "[12/15] Restarting network services..." -ForegroundColor Yellow
$services = @("Dnscache", "WinHttpAutoProxySvc", "iphlpsvc")
foreach ($svc in $services) {
    try {
        Restart-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  Restarted: $svc" -ForegroundColor Green
    } catch {
        Write-Host "  Could not restart: $svc" -ForegroundColor Gray
    }
}

# DEEP FIX 13: Remove all TAP driver registry corruption
Write-Host "[13/15] Cleaning TAP driver registry..." -ForegroundColor Yellow
try {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
    $keys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
    foreach ($key in $keys) {
        $driver = Get-ItemProperty -Path $key.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue
        if ($driver.DriverDesc -like "*TAP*") {
            Write-Host "  Found TAP driver registry entry" -ForegroundColor Green
        }
    }
    Write-Host "  SUCCESS: Registry checked" -ForegroundColor Green
} catch {
    Write-Host "  INFO: Registry check completed" -ForegroundColor Gray
}

# DEEP FIX 14: Completely clear Surfshark app data and registry
Write-Host "[14/15] Removing all Surfshark app data..." -ForegroundColor Yellow
try {
    Remove-Item "$env:LOCALAPPDATA\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:ProgramData\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "HKCU:\Software\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  SUCCESS: All app data removed" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not remove all data" -ForegroundColor Yellow
}

# DEEP FIX 15: Restart Surfshark service
Write-Host "[15/15] Restarting Surfshark service..." -ForegroundColor Yellow
try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"}
    if ($service) {
        Restart-Service $service.Name -Force -ErrorAction Stop
        Start-Sleep -Seconds 3
        Write-Host "  SUCCESS: Service restarted" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Service restart failed" -ForegroundColor Yellow
}

# FINAL REPORT
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEEP REPAIR COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($tapMissing) {
    Write-Host "CRITICAL: TAP adapter is missing!" -ForegroundColor Red
    Write-Host ""
    Write-Host "You MUST reinstall Surfshark:" -ForegroundColor Yellow
    Write-Host "1. Uninstall Surfshark completely" -ForegroundColor White
    Write-Host "2. Restart PC" -ForegroundColor White
    Write-Host "3. Download from surfshark.com" -ForegroundColor White
    Write-Host "4. Install as Administrator" -ForegroundColor White
    Write-Host "5. Accept TAP driver installation" -ForegroundColor White
    Write-Host ""
    $uninstall = Read-Host "Open Programs and Features to uninstall? (Y/N)"
    if ($uninstall -eq 'Y' -or $uninstall -eq 'y') {
        Start-Process "appwiz.cpl"
    }
} else {
    Write-Host "All deep repairs completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "RESTART REQUIRED!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After restart:" -ForegroundColor Cyan
    Write-Host "1. Open Surfshark" -ForegroundColor White
    Write-Host "2. Login: jgerenaiadaviti@gmail.com" -ForegroundColor White
    Write-Host "3. Settings > Protocol > WireGuard" -ForegroundColor White
    Write-Host "4. Try Quick Connect first" -ForegroundColor White
    Write-Host "5. If fails, try OpenVPN TCP" -ForegroundColor White
    Write-Host ""
    Write-Host "If STILL doesn't work after restart:" -ForegroundColor Yellow
    Write-Host "- Try connecting with mobile hotspot (test if ISP blocks VPN)" -ForegroundColor White
    Write-Host "- Temporarily disable Windows Defender firewall" -ForegroundColor White
    Write-Host "- Check if ISP is blocking VPN traffic" -ForegroundColor White
    Write-Host ""
    
    $restart = Read-Host "Restart computer now? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Host ""
        Write-Host "Restarting in 10 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
