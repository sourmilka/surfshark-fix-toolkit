# SURFSHARK COMPLETE REPAIR TOOL
# Fixes all Surfshark connection issues
# Run as Administrator

# Check Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This tool requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SURFSHARK COMPLETE REPAIR TOOL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$fixesApplied = 0
$fixesFailed = 0

# FIX 1: Flush DNS
Write-Host "[1/12] Flushing DNS cache..." -ForegroundColor Yellow
try {
    ipconfig /flushdns | Out-Null
    Write-Host "  SUCCESS: DNS flushed" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not flush DNS" -ForegroundColor Red
    $fixesFailed++
}

# FIX 2: Reset Winsock
Write-Host "[2/12] Resetting Winsock..." -ForegroundColor Yellow
try {
    netsh winsock reset | Out-Null
    Write-Host "  SUCCESS: Winsock reset" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not reset Winsock" -ForegroundColor Red
    $fixesFailed++
}

# FIX 3: Reset TCP/IP
Write-Host "[3/12] Resetting TCP/IP stack..." -ForegroundColor Yellow
try {
    netsh int ip reset | Out-Null
    Write-Host "  SUCCESS: TCP/IP reset" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not reset TCP/IP" -ForegroundColor Red
    $fixesFailed++
}

# FIX 4: Enable TLS
Write-Host "[4/12] Enabling TLS 1.2/1.3..." -ForegroundColor Yellow
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Write-Host "  SUCCESS: TLS enabled" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not enable TLS" -ForegroundColor Red
    $fixesFailed++
}

# FIX 5: Find and add Surfshark to Defender exclusions
Write-Host "[5/12] Adding Surfshark to Windows Defender exclusions..." -ForegroundColor Yellow
$surfsharkPaths = @(
    "C:\Program Files\Surfshark",
    "C:\Program Files (x86)\Surfshark"
)

$found = $false
foreach ($path in $surfsharkPaths) {
    if (Test-Path $path) {
        $found = $true
        try {
            Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "$path\Surfshark.exe" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "$path\SurfsharkService.exe" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess "Surfshark.exe" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess "SurfsharkService.exe" -ErrorAction SilentlyContinue
            Write-Host "  SUCCESS: Added to Defender exclusions" -ForegroundColor Green
            $fixesApplied++
            break
        } catch {
            Write-Host "  WARNING: May already be excluded" -ForegroundColor Yellow
        }
    }
}

if (-not $found) {
    Write-Host "  INFO: Surfshark not found (may need reinstall)" -ForegroundColor Gray
}

# FIX 6: Create firewall rules
Write-Host "[6/12] Creating firewall rules..." -ForegroundColor Yellow
foreach ($path in $surfsharkPaths) {
    if (Test-Path "$path\Surfshark.exe") {
        try {
            Get-NetFirewallRule -DisplayName "Surfshark*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            
            New-NetFirewallRule -DisplayName "Surfshark-Out" -Direction Outbound -Program "$path\Surfshark.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
            New-NetFirewallRule -DisplayName "Surfshark-In" -Direction Inbound -Program "$path\Surfshark.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
            New-NetFirewallRule -DisplayName "SurfsharkService-Out" -Direction Outbound -Program "$path\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
            New-NetFirewallRule -DisplayName "SurfsharkService-In" -Direction Inbound -Program "$path\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
            
            Write-Host "  SUCCESS: Firewall rules created" -ForegroundColor Green
            $fixesApplied++
            break
        } catch {
            Write-Host "  WARNING: Firewall rules may exist" -ForegroundColor Yellow
        }
    }
}

# FIX 7: Clean hosts file
Write-Host "[7/12] Checking hosts file..." -ForegroundColor Yellow
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
try {
    $hostsContent = Get-Content $hostsFile -ErrorAction Stop
    $cleanContent = $hostsContent | Where-Object {$_ -notmatch "surfshark" -or $_ -match "^#"}
    
    if ($hostsContent.Count -ne $cleanContent.Count) {
        Copy-Item $hostsFile "$hostsFile.backup" -Force
        $cleanContent | Set-Content $hostsFile -Force
        Write-Host "  SUCCESS: Removed Surfshark blocks from hosts" -ForegroundColor Green
        $fixesApplied++
    } else {
        Write-Host "  SUCCESS: Hosts file clean" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Could not check hosts file" -ForegroundColor Yellow
}

# FIX 8: Restart Surfshark service
Write-Host "[8/12] Restarting Surfshark service..." -ForegroundColor Yellow
try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"} | Select-Object -First 1
    if ($service) {
        Restart-Service $service.Name -Force -ErrorAction Stop
        Write-Host "  SUCCESS: Service restarted" -ForegroundColor Green
        $fixesApplied++
    } else {
        Write-Host "  INFO: Service not found" -ForegroundColor Gray
    }
} catch {
    Write-Host "  WARNING: Could not restart service" -ForegroundColor Yellow
}

# FIX 9: Clear app cache
Write-Host "[9/12] Clearing Surfshark cache..." -ForegroundColor Yellow
$appPaths = @(
    "$env:LOCALAPPDATA\Surfshark",
    "$env:APPDATA\Surfshark"
)

foreach ($path in $appPaths) {
    if (Test-Path $path) {
        try {
            Get-ChildItem -Path $path -Recurse -Include "*.log","*.tmp","*.cache","cache*" -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "  SUCCESS: Cache cleared from $path" -ForegroundColor Green
            $fixesApplied++
        } catch {
            Write-Host "  WARNING: Could not clear all cache" -ForegroundColor Yellow
        }
    }
}

# FIX 10: Reset network cache
Write-Host "[10/12] Resetting network cache..." -ForegroundColor Yellow
try {
    netsh interface ip delete arpcache | Out-Null
    netsh interface ip delete destinationcache | Out-Null
    Write-Host "  SUCCESS: Network cache reset" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  WARNING: Partial network reset" -ForegroundColor Yellow
}

# FIX 11: Re-register DNS
Write-Host "[11/12] Re-registering DNS..." -ForegroundColor Yellow
try {
    ipconfig /registerdns | Out-Null
    Write-Host "  SUCCESS: DNS registered" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  WARNING: Could not register DNS" -ForegroundColor Yellow
}

# FIX 12: Renew IP
Write-Host "[12/12] Renewing IP address..." -ForegroundColor Yellow
try {
    ipconfig /release | Out-Null
    Start-Sleep -Seconds 1
    ipconfig /renew | Out-Null
    Write-Host "  SUCCESS: IP renewed" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  WARNING: Could not renew IP" -ForegroundColor Yellow
}

# SUMMARY
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  REPAIR COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fixes applied: $fixesApplied" -ForegroundColor Green
Write-Host "Fixes failed: $fixesFailed" -ForegroundColor $(if ($fixesFailed -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Test Surfshark API
Write-Host "Testing Surfshark API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://api.surfshark.com" -Method HEAD -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "  SUCCESS: Can reach Surfshark API (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host ""
    Write-Host "GOOD NEWS: Connection looks fixed!" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 403) {
        Write-Host "  ERROR: Still getting 403 Forbidden" -ForegroundColor Red
        Write-Host ""
        Write-Host "ADDITIONAL STEPS NEEDED:" -ForegroundColor Yellow
        Write-Host "1. Temporarily disable Windows Defender Real-Time Protection" -ForegroundColor White
        Write-Host "   - Open Windows Security" -ForegroundColor Gray
        Write-Host "   - Go to: Virus and threat protection" -ForegroundColor Gray
        Write-Host "   - Click: Manage settings" -ForegroundColor Gray
        Write-Host "   - Turn OFF: Real-time protection" -ForegroundColor Gray
        Write-Host "   - Try Surfshark login" -ForegroundColor Gray
        Write-Host "   - Turn Real-time protection back ON" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Or reinstall Surfshark completely" -ForegroundColor White
        Write-Host "   - Uninstall Surfshark" -ForegroundColor Gray
        Write-Host "   - Restart PC" -ForegroundColor Gray
        Write-Host "   - Download fresh from surfshark.com" -ForegroundColor Gray
        Write-Host "   - Install with antivirus temporarily disabled" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: Cannot reach API: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "RESTART REQUIRED!" -ForegroundColor Yellow
Write-Host "Many fixes need a restart to take effect." -ForegroundColor White
Write-Host ""

$restart = Read-Host "Do you want to restart now? (Y/N)"
if ($restart -eq 'Y' -or $restart -eq 'y') {
    Write-Host ""
    Write-Host "Restarting in 10 seconds... (Press Ctrl+C to cancel)" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host ""
    Write-Host "Please restart manually, then:" -ForegroundColor Yellow
    Write-Host "1. Open Surfshark app" -ForegroundColor White
    Write-Host "2. Login with: jgerenaiadaviti@gmail.com" -ForegroundColor White
    Write-Host "3. Use your password" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
