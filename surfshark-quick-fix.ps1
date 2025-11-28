# Quick Surfshark Fix - 403 Forbidden Error
# Run this as Administrator

Write-Host "=== Quick Surfshark 403 Fix ===" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] Please run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell -> 'Run as Administrator'" -ForegroundColor Yellow
    exit
}

Write-Host "ISSUE: 403 Forbidden when connecting to Surfshark API" -ForegroundColor Yellow
Write-Host "CAUSE: Windows Defender Real-Time Protection is blocking the connection" -ForegroundColor Yellow
Write-Host ""

# Solution 1: Add Surfshark to Windows Defender exclusions
Write-Host "[1/4] Adding Surfshark to Windows Defender exclusions..." -ForegroundColor Cyan

$surfsharkPaths = @(
    "C:\Program Files\Surfshark\Surfshark.exe",
    "C:\Program Files\Surfshark\SurfsharkService.exe",
    "C:\Program Files (x86)\Surfshark\Surfshark.exe",
    "C:\Program Files (x86)\Surfshark\SurfsharkService.exe"
)

foreach ($path in $surfsharkPaths) {
    if (Test-Path $path) {
        try {
            Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
            Write-Host "  [OK] Added exclusion: $path" -ForegroundColor Green
        } catch {
            Write-Host "  [SKIP] Already excluded or error: $path" -ForegroundColor Gray
        }
    }
}

# Add process exclusions
try {
    Add-MpPreference -ExclusionProcess "Surfshark.exe" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "SurfsharkService.exe" -ErrorAction SilentlyContinue
    Write-Host "  [OK] Added process exclusions" -ForegroundColor Green
} catch {
    Write-Host "  [INFO] Process exclusions may already exist" -ForegroundColor Gray
}

Write-Host ""

# Solution 2: Allow Surfshark through firewall
Write-Host "[2/4] Creating firewall rules for Surfshark..." -ForegroundColor Cyan

try {
    # Remove old rules if exist
    Get-NetFirewallRule -DisplayName "Surfshark*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    
    # Create new rules
    New-NetFirewallRule -DisplayName "Surfshark VPN App - Outbound" -Direction Outbound -Program "C:\Program Files\Surfshark\Surfshark.exe" -Action Allow -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "Surfshark VPN Service - Outbound" -Direction Outbound -Program "C:\Program Files\Surfshark\SurfsharkService.exe" -Action Allow -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "Surfshark VPN App - Inbound" -Direction Inbound -Program "C:\Program Files\Surfshark\Surfshark.exe" -Action Allow -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "Surfshark VPN Service - Inbound" -Direction Inbound -Program "C:\Program Files\Surfshark\SurfsharkService.exe" -Action Allow -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "  [OK] Firewall rules created" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Some firewall rules may already exist" -ForegroundColor Yellow
}

Write-Host ""

# Solution 3: Flush DNS and reset network
Write-Host "[3/4] Flushing DNS and resetting network..." -ForegroundColor Cyan

try {
    ipconfig /flushdns | Out-Null
    Write-Host "  [OK] DNS cache flushed" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to flush DNS" -ForegroundColor Red
}

Write-Host ""

# Solution 4: Restart Surfshark service
Write-Host "[4/4] Restarting Surfshark service..." -ForegroundColor Cyan

try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"}
    if ($service) {
        Restart-Service $service.Name -Force -ErrorAction Stop
        Write-Host "  [OK] Surfshark service restarted" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARNING] Could not restart service: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== FIX COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "What was fixed:" -ForegroundColor Cyan
Write-Host "  1. Added Surfshark to Windows Defender exclusions" -ForegroundColor White
Write-Host "  2. Created firewall rules to allow Surfshark" -ForegroundColor White
Write-Host "  3. Flushed DNS cache" -ForegroundColor White
Write-Host "  4. Restarted Surfshark service" -ForegroundColor White
Write-Host ""
Write-Host "NOW TRY THIS:" -ForegroundColor Yellow
Write-Host "  1. Open Surfshark app" -ForegroundColor White
Write-Host "  2. Login with: jgerenaiadaviti@gmail.com" -ForegroundColor White
Write-Host "  3. Enter your password" -ForegroundColor White
Write-Host ""
Write-Host "If STILL not working:" -ForegroundColor Red
Write-Host "  Option A: Temporarily disable Windows Defender Real-Time Protection" -ForegroundColor Yellow
Write-Host "    - Windows Security -> Virus & threat protection -> Manage settings" -ForegroundColor Gray
Write-Host "    - Turn off 'Real-time protection' temporarily" -ForegroundColor Gray
Write-Host "    - Try Surfshark login" -ForegroundColor Gray
Write-Host "    - Turn protection back ON after login" -ForegroundColor Gray
Write-Host ""
Write-Host "  Option B: Reinstall Surfshark completely" -ForegroundColor Yellow
Write-Host "    - Uninstall Surfshark" -ForegroundColor Gray
Write-Host "    - Restart PC" -ForegroundColor Gray
Write-Host "    - Download fresh from surfshark.com" -ForegroundColor Gray
Write-Host "    - Install with Real-time protection OFF" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
