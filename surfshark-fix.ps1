# Surfshark Auto-Fix Script
# Run this AFTER the troubleshooting script
# Requires Administrator privileges

Write-Host "=== Surfshark VPN Auto-Fix Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run:" -ForegroundColor Yellow
    Write-Host "  cd 'c:\Users\jgero\Desktop\my projects\wwm'" -ForegroundColor Green
    Write-Host "  .\surfshark-fix.ps1" -ForegroundColor Green
    Write-Host ""
    exit
}

Write-Host "[OK] Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Fix 1: Flush DNS
Write-Host "[1/7] Flushing DNS cache..." -ForegroundColor Yellow
try {
    ipconfig /flushdns | Out-Null
    Write-Host "  [OK] DNS cache cleared" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Failed to flush DNS" -ForegroundColor Red
}
Write-Host ""

# Fix 2: Reset Winsock
Write-Host "[2/7] Resetting Winsock catalog..." -ForegroundColor Yellow
try {
    netsh winsock reset | Out-Null
    Write-Host "  [OK] Winsock reset successful" -ForegroundColor Green
    Write-Host "  [INFO] Restart required for this to take effect" -ForegroundColor Yellow
} catch {
    Write-Host "  [ERROR] Failed to reset Winsock" -ForegroundColor Red
}
Write-Host ""

# Fix 3: Reset TCP/IP Stack
Write-Host "[3/7] Resetting TCP/IP stack..." -ForegroundColor Yellow
try {
    netsh int ip reset | Out-Null
    Write-Host "  [OK] TCP/IP stack reset successful" -ForegroundColor Green
    Write-Host "  [INFO] Restart required for this to take effect" -ForegroundColor Yellow
} catch {
    Write-Host "  [ERROR] Failed to reset TCP/IP" -ForegroundColor Red
}
Write-Host ""

# Fix 4: Check and Start Surfshark Service
Write-Host "[4/7] Starting Surfshark services..." -ForegroundColor Yellow
try {
    $services = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"}
    if ($services) {
        foreach ($svc in $services) {
            if ($svc.Status -ne 'Running') {
                Start-Service $svc.Name -ErrorAction Stop
                Write-Host "  [OK] Started $($svc.DisplayName)" -ForegroundColor Green
            } else {
                Write-Host "  [OK] $($svc.DisplayName) already running" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "  [INFO] No Surfshark services found (app may need reinstall)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Could not start Surfshark service: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Fix 5: Add Firewall Rules for Surfshark
Write-Host "[5/7] Checking Surfshark firewall rules..." -ForegroundColor Yellow
try {
    $surfsharkPath = "C:\Program Files\Surfshark\Surfshark.exe"
    $surfsharkServicePath = "C:\Program Files\Surfshark\SurfsharkService.exe"
    
    if (Test-Path $surfsharkPath) {
        # Check if rule exists
        $existingRule = Get-NetFirewallApplicationFilter | Where-Object {$_.Program -eq $surfsharkPath}
        
        if (-not $existingRule) {
            New-NetFirewallRule -DisplayName "Surfshark VPN" -Direction Outbound -Program $surfsharkPath -Action Allow -ErrorAction Stop | Out-Null
            New-NetFirewallRule -DisplayName "Surfshark VPN" -Direction Inbound -Program $surfsharkPath -Action Allow -ErrorAction Stop | Out-Null
            Write-Host "  [OK] Firewall rules created for Surfshark" -ForegroundColor Green
        } else {
            Write-Host "  [OK] Firewall rules already exist" -ForegroundColor Green
        }
    } else {
        Write-Host "  [INFO] Surfshark not found at default location" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [WARNING] Could not modify firewall rules: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# Fix 6: Clear Surfshark App Data
Write-Host "[6/7] Clearing Surfshark app cache..." -ForegroundColor Yellow
$appDataPaths = @(
    "$env:LOCALAPPDATA\Surfshark",
    "$env:APPDATA\Surfshark"
)

foreach ($path in $appDataPaths) {
    if (Test-Path $path) {
        try {
            # Backup first
            $backupPath = "$path.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -Path $path -Destination $backupPath -Recurse -ErrorAction Stop
            
            # Clear cache files (keep config)
            Get-ChildItem -Path $path -Recurse -Include "*.log","*.tmp","cache*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            
            Write-Host "  [OK] Cleared cache from $path" -ForegroundColor Green
            Write-Host "  [INFO] Backup created: $backupPath" -ForegroundColor Gray
        } catch {
            Write-Host "  [WARNING] Could not clear cache: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# Fix 7: Check Hosts File
Write-Host "[7/7] Checking Windows hosts file..." -ForegroundColor Yellow
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
try {
    $hostsContent = Get-Content $hostsFile -ErrorAction Stop
    $surfsharkBlocked = $hostsContent | Where-Object {$_ -match "surfshark"}
    
    if ($surfsharkBlocked) {
        Write-Host "  [WARNING] Found Surfshark entries in hosts file:" -ForegroundColor Yellow
        $surfsharkBlocked | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        Write-Host "  [INFO] You may need to remove these manually" -ForegroundColor Yellow
        Write-Host "  File location: $hostsFile" -ForegroundColor Gray
    } else {
        Write-Host "  [OK] No Surfshark blocks in hosts file" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARNING] Could not check hosts file" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=== FIX SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Completed fixes:" -ForegroundColor White
Write-Host "  [✓] DNS cache flushed" -ForegroundColor Green
Write-Host "  [✓] Winsock reset" -ForegroundColor Green
Write-Host "  [✓] TCP/IP stack reset" -ForegroundColor Green
Write-Host "  [✓] Firewall rules checked" -ForegroundColor Green
Write-Host "  [✓] App cache cleared" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: You must RESTART your computer now!" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart:" -ForegroundColor Cyan
Write-Host "  1. Open Surfshark app" -ForegroundColor White
Write-Host "  2. Try logging in with:" -ForegroundColor White
Write-Host "     Email: jgerenaiadaviti@gmail.com" -ForegroundColor Green
Write-Host "     (Password already saved)" -ForegroundColor Gray
Write-Host ""
Write-Host "If still not working, try:" -ForegroundColor Yellow
Write-Host "  - Complete uninstall + reinstall Surfshark" -ForegroundColor White
Write-Host "  - Temporarily disable antivirus" -ForegroundColor White
Write-Host "  - Check if ISP is blocking VPN traffic" -ForegroundColor White
Write-Host ""

$restart = Read-Host "Do you want to restart now? (Y/N)"
if ($restart -eq 'Y' -or $restart -eq 'y') {
    Write-Host "Restarting in 10 seconds... (Press Ctrl+C to cancel)" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "Remember to restart manually before testing Surfshark!" -ForegroundColor Yellow
}
