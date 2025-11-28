# Complete Network Stack Reset
# Nuclear option - use when nothing else works
# Version: 1.0.0
# Requires: Administrator privileges

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch]$Force
)

Clear-Host

Write-Host "========================================" -ForegroundColor Red
Write-Host "  COMPLETE NETWORK STACK RESET" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "WARNING: This will reset ALL network settings!" -ForegroundColor Yellow
Write-Host "  - All network adapters will be reset" -ForegroundColor Yellow
Write-Host "  - All firewall rules will be cleared" -ForegroundColor Yellow
Write-Host "  - DNS and IP configuration will be reset" -ForegroundColor Yellow
Write-Host "  - VPN settings will be cleared" -ForegroundColor Yellow
Write-Host "  - A restart is REQUIRED after completion" -ForegroundColor Yellow
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to continue? (Type YES to proceed)"
    if ($confirm -ne "YES") {
        Write-Host "Operation cancelled." -ForegroundColor Gray
        exit
    }
}

Write-Host ""
Write-Host "Starting complete network reset..." -ForegroundColor Cyan
Write-Host ""

# Reset 1: Winsock
Write-Host "[1/10] Resetting Winsock..." -ForegroundColor Yellow
netsh winsock reset
Write-Host "  Complete" -ForegroundColor Green

# Reset 2: TCP/IP
Write-Host "[2/10] Resetting TCP/IP stack..." -ForegroundColor Yellow
netsh int ip reset
Write-Host "  Complete" -ForegroundColor Green

# Reset 3: Firewall
Write-Host "[3/10] Resetting Windows Firewall..." -ForegroundColor Yellow
netsh advfirewall reset
Write-Host "  Complete" -ForegroundColor Green

# Reset 4: DNS
Write-Host "[4/10] Flushing DNS..." -ForegroundColor Yellow
ipconfig /flushdns
Write-Host "  Complete" -ForegroundColor Green

# Reset 5: Release/Renew IP
Write-Host "[5/10] Releasing IP address..." -ForegroundColor Yellow
ipconfig /release
Write-Host "[6/10] Renewing IP address..." -ForegroundColor Yellow
ipconfig /renew
Write-Host "  Complete" -ForegroundColor Green

# Reset 7: Windows Filtering Platform
Write-Host "[7/10] Resetting Windows Filtering Platform..." -ForegroundColor Yellow
netsh wfp reset
Write-Host "  Complete" -ForegroundColor Green

# Reset 8: Disable tunnels
Write-Host "[8/10] Disabling tunnel adapters..." -ForegroundColor Yellow
netsh interface teredo set state disabled
netsh interface 6to4 set state disabled
netsh interface isatap set state disabled
Write-Host "  Complete" -ForegroundColor Green

# Reset 9: Network adapters
Write-Host "[9/10] Resetting network adapters..." -ForegroundColor Yellow
Get-NetAdapter | ForEach-Object {
    netsh interface set interface $_.Name admin=disable
    Start-Sleep -Milliseconds 500
    netsh interface set interface $_.Name admin=enable
}
Write-Host "  Complete" -ForegroundColor Green

# Reset 10: Clear routes
Write-Host "[10/10] Clearing routing table..." -ForegroundColor Yellow
route -f
Write-Host "  Complete" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  NETWORK RESET COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "YOU MUST RESTART YOUR COMPUTER NOW!" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart:" -ForegroundColor Cyan
Write-Host "  1. Your network will be completely reset" -ForegroundColor White
Write-Host "  2. Reinstall Surfshark from surfshark.com" -ForegroundColor White
Write-Host "  3. Login and test connection" -ForegroundColor White
Write-Host ""

$restart = Read-Host "Restart now? (Y/N)"
if ($restart -eq 'Y' -or $restart -eq 'y') {
    Write-Host "Restarting in 10 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host ""
    Write-Host "Remember to restart before using network!" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
}
