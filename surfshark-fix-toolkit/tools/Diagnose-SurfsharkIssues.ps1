# Surfshark Diagnostic Tool
# Identifies issues without making changes
# Version: 1.0.0

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Surfshark Diagnostic Tool v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()

# CHECK 1: Internet Connectivity
Write-Host "[1/8] Testing internet connectivity..." -ForegroundColor Yellow
try {
    $pingTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
    if ($pingTest) {
        Write-Host "  OK: Internet connection working" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: No internet connection" -ForegroundColor Red
        $issues += "No internet connection"
    }
} catch {
    Write-Host "  WARN: Cannot test connection" -ForegroundColor Yellow
}

# CHECK 2: DNS Resolution
Write-Host "[2/8] Testing DNS resolution..." -ForegroundColor Yellow
$domains = @("surfshark.com", "api.surfshark.com", "my.surfshark.com")
foreach ($domain in $domains) {
    try {
        $resolved = Resolve-DnsName -Name $domain -ErrorAction Stop -QuickTimeout
        Write-Host "  OK: $domain resolved" -ForegroundColor Green
    } catch {
        Write-Host "  FAIL: Cannot resolve $domain" -ForegroundColor Red
        $issues += "DNS resolution failed for $domain"
    }
}

# CHECK 3: Surfshark API
Write-Host "[3/8] Testing Surfshark API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://api.surfshark.com" -Method HEAD -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "  OK: API reachable (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 403) {
        Write-Host "  FAIL: 403 Forbidden (firewall/antivirus blocking)" -ForegroundColor Red
        $issues += "403 Forbidden error - Windows Defender or firewall blocking"
    } else {
        Write-Host "  FAIL: Cannot reach API" -ForegroundColor Red
        $issues += "Cannot reach Surfshark API"
    }
}

# CHECK 4: Surfshark Installation
Write-Host "[4/8] Checking Surfshark installation..." -ForegroundColor Yellow
$paths = @("C:\Program Files\Surfshark", "C:\Program Files (x86)\Surfshark")
$found = $false
foreach ($path in $paths) {
    if (Test-Path "$path\Surfshark.exe") {
        Write-Host "  OK: Found at $path" -ForegroundColor Green
        $found = $true
        break
    }
}
if (-not $found) {
    Write-Host "  FAIL: Surfshark not installed" -ForegroundColor Red
    $issues += "Surfshark not installed"
}

# CHECK 5: Surfshark Service
Write-Host "[5/8] Checking Surfshark service..." -ForegroundColor Yellow
$service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"} | Select-Object -First 1
if ($service) {
    if ($service.Status -eq 'Running') {
        Write-Host "  OK: Service is running" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Service is $($service.Status)" -ForegroundColor Yellow
        $issues += "Surfshark service not running"
    }
} else {
    Write-Host "  FAIL: Service not found" -ForegroundColor Red
    $issues += "Surfshark service missing"
}

# CHECK 6: TAP Adapter
Write-Host "[6/8] Checking VPN TAP adapter..." -ForegroundColor Yellow
$tapAdapter = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like "*TAP*" -or $_.InterfaceDescription -like "*Surfshark*"
}
if ($tapAdapter) {
    Write-Host "  OK: TAP adapter found ($($tapAdapter.Status))" -ForegroundColor Green
    if ($tapAdapter.Status -ne 'Up' -and $tapAdapter.Status -ne 'Disconnected') {
        $issues += "TAP adapter is $($tapAdapter.Status)"
    }
} else {
    Write-Host "  FAIL: TAP adapter not found" -ForegroundColor Red
    $issues += "TAP adapter missing - reinstall required"
}

# CHECK 7: Firewall
Write-Host "[7/8] Checking firewall rules..." -ForegroundColor Yellow
$rules = Get-NetFirewallApplicationFilter | Where-Object {$_.Program -like "*Surfshark*"}
if ($rules) {
    Write-Host "  OK: Firewall rules exist" -ForegroundColor Green
} else {
    Write-Host "  WARN: No firewall rules found" -ForegroundColor Yellow
    $issues += "Firewall rules missing"
}

# CHECK 8: Conflicts
Write-Host "[8/8] Checking for conflicts..." -ForegroundColor Yellow
$conflicts = Get-NetAdapter | Where-Object {
    ($_.InterfaceDescription -like "*Hyper-V*" -or $_.InterfaceDescription -like "*VMware*") -and $_.Status -eq 'Up'
}
if ($conflicts) {
    Write-Host "  WARN: Found Hyper-V/VMware adapters" -ForegroundColor Yellow
    $issues += "Hyper-V or VMware adapters may conflict"
} else {
    Write-Host "  OK: No conflicts detected" -ForegroundColor Green
}

# SUMMARY
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "No issues detected! Surfshark should be working." -ForegroundColor Green
    Write-Host ""
    Write-Host "If you still have problems:" -ForegroundColor Cyan
    Write-Host "  - Try switching VPN protocol (Settings > Protocol)" -ForegroundColor White
    Write-Host "  - Use Quick Connect instead of specific location" -ForegroundColor White
} else {
    Write-Host "Found $($issues.Count) issue(s):" -ForegroundColor Yellow
    Write-Host ""
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "RECOMMENDED ACTION:" -ForegroundColor Cyan
    
    if ($issues -match "403 Forbidden") {
        Write-Host "  Run: Fix-SurfsharkLogin.ps1" -ForegroundColor Green
    } elseif ($issues -match "TAP adapter") {
        Write-Host "  Reinstall Surfshark from surfshark.com" -ForegroundColor Green
    } elseif ($issues -match "Cannot reach") {
        Write-Host "  Run: Fix-SurfsharkLogin.ps1" -ForegroundColor Green
    } elseif ($issues -match "Service" -or $issues -match "Hyper-V") {
        Write-Host "  Run: Fix-SurfsharkConnection.ps1" -ForegroundColor Green
    } else {
        Write-Host "  Run: Fix-SurfsharkLogin.ps1 then Fix-SurfsharkConnection.ps1" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
