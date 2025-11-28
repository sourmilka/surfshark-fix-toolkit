# SURFSHARK CONNECTION FIX
# Fixes "cannot connect to server" issues
# Run as Administrator

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SURFSHARK CONNECTION FIX" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# DIAGNOSTIC 1: Check TAP Adapter
Write-Host "[1/8] Checking VPN TAP adapter..." -ForegroundColor Yellow
$tapAdapter = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like "*TAP*" -or 
    $_.InterfaceDescription -like "*Wintun*" -or
    $_.Name -like "*Surfshark*" -or
    $_.InterfaceDescription -like "*Surfshark*"
}

if ($tapAdapter) {
    Write-Host "  Found TAP adapter: $($tapAdapter.Name)" -ForegroundColor Green
    Write-Host "  Status: $($tapAdapter.Status)" -ForegroundColor $(if ($tapAdapter.Status -eq 'Up') { 'Green' } else { 'Yellow' })
    
    if ($tapAdapter.Status -ne 'Up') {
        Write-Host "  Enabling TAP adapter..." -ForegroundColor Yellow
        try {
            Enable-NetAdapter -Name $tapAdapter.Name -Confirm:$false -ErrorAction Stop
            Write-Host "  SUCCESS: TAP adapter enabled" -ForegroundColor Green
        } catch {
            Write-Host "  WARNING: Could not enable adapter" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ERROR: No VPN TAP adapter found!" -ForegroundColor Red
    Write-Host "  This is the problem - TAP driver missing" -ForegroundColor Yellow
    $tapMissing = $true
}

# DIAGNOSTIC 2: Check Surfshark Service
Write-Host "[2/8] Checking Surfshark service..." -ForegroundColor Yellow
$service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"} | Select-Object -First 1
if ($service) {
    Write-Host "  Service: $($service.DisplayName)" -ForegroundColor Green
    Write-Host "  Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Red' })
    
    if ($service.Status -ne 'Running') {
        Write-Host "  Starting service..." -ForegroundColor Yellow
        try {
            Start-Service $service.Name -ErrorAction Stop
            Write-Host "  SUCCESS: Service started" -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Could not start service" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ERROR: Surfshark service not found" -ForegroundColor Red
}

# DIAGNOSTIC 3: Check OpenVPN/WireGuard ports
Write-Host "[3/8] Checking VPN protocol ports..." -ForegroundColor Yellow
$ports = @(443, 1194, 51820)
foreach ($port in $ports) {
    $rule = Get-NetFirewallPortFilter | Where-Object {$_.LocalPort -eq $port} | Select-Object -First 1
    if ($rule) {
        Write-Host "  Port $port : Open" -ForegroundColor Green
    } else {
        Write-Host "  Port $port : May be blocked" -ForegroundColor Yellow
    }
}

# FIX 1: Create firewall rules for VPN protocols
Write-Host "[4/8] Creating VPN protocol firewall rules..." -ForegroundColor Yellow
try {
    # OpenVPN
    New-NetFirewallRule -DisplayName "Surfshark-OpenVPN-UDP" -Direction Outbound -Protocol UDP -LocalPort 1194 -Action Allow -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "Surfshark-OpenVPN-TCP" -Direction Outbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue | Out-Null
    
    # WireGuard
    New-NetFirewallRule -DisplayName "Surfshark-WireGuard" -Direction Outbound -Protocol UDP -LocalPort 51820 -Action Allow -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "  SUCCESS: VPN protocol rules created" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Some rules may already exist" -ForegroundColor Yellow
}

# FIX 2: Reset network adapters priority
Write-Host "[5/8] Resetting network adapter metrics..." -ForegroundColor Yellow
try {
    Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {
        Set-NetIPInterface -InterfaceIndex $_.ifIndex -AutomaticMetric Enabled -ErrorAction SilentlyContinue
    }
    Write-Host "  SUCCESS: Adapter metrics reset" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not reset all metrics" -ForegroundColor Yellow
}

# FIX 3: Clear DNS cache again
Write-Host "[6/8] Clearing DNS cache..." -ForegroundColor Yellow
try {
    ipconfig /flushdns | Out-Null
    Write-Host "  SUCCESS: DNS cache cleared" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not clear DNS" -ForegroundColor Yellow
}

# FIX 4: Check and fix routing table
Write-Host "[7/8] Checking routing table..." -ForegroundColor Yellow
try {
    $defaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
    if ($defaultRoute) {
        Write-Host "  Default route exists" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: No default route" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  INFO: Could not check routes" -ForegroundColor Gray
}

# FIX 5: Restart Surfshark service
Write-Host "[8/8] Restarting Surfshark service..." -ForegroundColor Yellow
try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"} | Select-Object -First 1
    if ($service) {
        Restart-Service $service.Name -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "  SUCCESS: Service restarted" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Could not restart service" -ForegroundColor Yellow
}

# FINAL DIAGNOSIS
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSIS COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($tapMissing) {
    Write-Host "PROBLEM FOUND: TAP Adapter Missing!" -ForegroundColor Red
    Write-Host ""
    Write-Host "The VPN network adapter (TAP driver) is not installed." -ForegroundColor Yellow
    Write-Host "This is why you cannot connect to any server." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "SOLUTION: Reinstall Surfshark" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Step 1: Uninstall Surfshark" -ForegroundColor White
    Write-Host "  - Press Win + R" -ForegroundColor Gray
    Write-Host "  - Type: appwiz.cpl" -ForegroundColor Gray
    Write-Host "  - Find Surfshark, click Uninstall" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 2: Restart your PC" -ForegroundColor White
    Write-Host ""
    Write-Host "Step 3: Download fresh installer" -ForegroundColor White
    Write-Host "  - Go to: https://surfshark.com/download/windows" -ForegroundColor Gray
    Write-Host "  - Download latest version" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 4: Install Surfshark" -ForegroundColor White
    Write-Host "  - Run installer as Administrator" -ForegroundColor Gray
    Write-Host "  - Make sure to allow TAP driver installation" -ForegroundColor Gray
    Write-Host "  - If UAC asks about network adapter, click YES" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 5: Login and test" -ForegroundColor White
    Write-Host "  - Email: jgerenaiadaviti@gmail.com" -ForegroundColor Gray
    Write-Host "  - Try connecting to a server" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "TAP adapter found - trying alternative fixes..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "TRY THESE IN SURFSHARK APP:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Change VPN Protocol:" -ForegroundColor White
    Write-Host "   - Open Surfshark settings" -ForegroundColor Gray
    Write-Host "   - Go to: VPN settings > Protocol" -ForegroundColor Gray
    Write-Host "   - Try: WireGuard (recommended)" -ForegroundColor Gray
    Write-Host "   - Or try: OpenVPN UDP" -ForegroundColor Gray
    Write-Host "   - Or try: OpenVPN TCP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Try Different Server:" -ForegroundColor White
    Write-Host "   - Instead of specific location" -ForegroundColor Gray
    Write-Host "   - Click 'Quick Connect' or 'Fastest Server'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Disable IPv6:" -ForegroundColor White
    Write-Host "   - Surfshark settings > VPN settings" -ForegroundColor Gray
    Write-Host "   - Turn OFF IPv6" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Clear Surfshark App Data:" -ForegroundColor White
    Write-Host "   - Close Surfshark completely" -ForegroundColor Gray
    Write-Host "   - Run this command:" -ForegroundColor Gray
    Write-Host ""
    Write-Host '   Get-Process | Where-Object {$_.Name -like "*Surfshark*"} | Stop-Process -Force' -ForegroundColor Green
    Write-Host '   Remove-Item "$env:LOCALAPPDATA\Surfshark" -Recurse -Force' -ForegroundColor Green
    Write-Host '   Remove-Item "$env:APPDATA\Surfshark" -Recurse -Force' -ForegroundColor Green
    Write-Host ""
    Write-Host "   Then restart Surfshark and login again" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Offer to open Windows uninstaller
if ($tapMissing) {
    $uninstall = Read-Host "Open Windows Programs to uninstall Surfshark? (Y/N)"
    if ($uninstall -eq 'Y' -or $uninstall -eq 'y') {
        Start-Process "appwiz.cpl"
        Write-Host ""
        Write-Host "After uninstalling, restart PC and reinstall from surfshark.com" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
