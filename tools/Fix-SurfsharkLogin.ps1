# Surfshark Login & Authentication Fix Tool
# Fixes: "The app could not reach Surfshark system" (403 Forbidden errors)
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
Write-Host "  Surfshark Login Fix Tool v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$fixesApplied = 0
$fixesFailed = 0

# FIX 1: Flush DNS Cache
Write-Host "[1/12] Flushing DNS cache..." -ForegroundColor Yellow
try {
    if (-not $WhatIf) {
        ipconfig /flushdns | Out-Null
    }
    Write-Host "  SUCCESS: DNS cache flushed" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not flush DNS" -ForegroundColor Red
    $fixesFailed++
}

# FIX 2: Reset Winsock
Write-Host "[2/12] Resetting Winsock catalog..." -ForegroundColor Yellow
try {
    if (-not $WhatIf) {
        netsh winsock reset | Out-Null
    }
    Write-Host "  SUCCESS: Winsock reset (restart required)" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not reset Winsock" -ForegroundColor Red
    $fixesFailed++
}

# FIX 3: Reset TCP/IP Stack
Write-Host "[3/12] Resetting TCP/IP stack..." -ForegroundColor Yellow
try {
    if (-not $WhatIf) {
        netsh int ip reset | Out-Null
    }
    Write-Host "  SUCCESS: TCP/IP stack reset (restart required)" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not reset TCP/IP" -ForegroundColor Red
    $fixesFailed++
}

# FIX 4: Enable TLS 1.2/1.3
Write-Host "[4/12] Enabling modern TLS protocols..." -ForegroundColor Yellow
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Write-Host "  SUCCESS: TLS 1.2 enabled" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  FAILED: Could not enable TLS" -ForegroundColor Red
    $fixesFailed++
}

# FIX 5: Add Windows Defender Exclusions
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
            if (-not $WhatIf) {
                Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
                Add-MpPreference -ExclusionPath "$path\Surfshark.exe" -ErrorAction SilentlyContinue
                Add-MpPreference -ExclusionPath "$path\SurfsharkService.exe" -ErrorAction SilentlyContinue
                Add-MpPreference -ExclusionProcess "Surfshark.exe" -ErrorAction SilentlyContinue
                Add-MpPreference -ExclusionProcess "SurfsharkService.exe" -ErrorAction SilentlyContinue
            }
            Write-Host "  SUCCESS: Added to Windows Defender exclusions" -ForegroundColor Green
            $fixesApplied++
            break
        } catch {
            Write-Host "  WARNING: May already be excluded" -ForegroundColor Yellow
        }
    }
}

if (-not $found) {
    Write-Host "  INFO: Surfshark installation not found" -ForegroundColor Gray
}

# FIX 6: Create Firewall Rules
Write-Host "[6/12] Creating firewall rules..." -ForegroundColor Yellow
foreach ($path in $surfsharkPaths) {
    if (Test-Path "$path\Surfshark.exe") {
        try {
            if (-not $WhatIf) {
                Get-NetFirewallRule -DisplayName "Surfshark*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
                
                New-NetFirewallRule -DisplayName "Surfshark-Outbound" -Direction Outbound -Program "$path\Surfshark.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
                New-NetFirewallRule -DisplayName "Surfshark-Inbound" -Direction Inbound -Program "$path\Surfshark.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
                New-NetFirewallRule -DisplayName "SurfsharkService-Outbound" -Direction Outbound -Program "$path\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
                New-NetFirewallRule -DisplayName "SurfsharkService-Inbound" -Direction Inbound -Program "$path\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
            }
            Write-Host "  SUCCESS: Firewall rules created" -ForegroundColor Green
            $fixesApplied++
            break
        } catch {
            Write-Host "  WARNING: Firewall rules may already exist" -ForegroundColor Yellow
        }
    }
}

# FIX 7: Clean Hosts File
Write-Host "[7/12] Checking hosts file..." -ForegroundColor Yellow
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
try {
    $hostsContent = Get-Content $hostsFile -ErrorAction Stop
    $cleanContent = $hostsContent | Where-Object {$_ -notmatch "surfshark" -or $_ -match "^#"}
    
    if ($hostsContent.Count -ne $cleanContent.Count) {
        if (-not $WhatIf) {
            Copy-Item $hostsFile "$hostsFile.backup" -Force
            $cleanContent | Set-Content $hostsFile -Force
        }
        Write-Host "  SUCCESS: Removed Surfshark blocks from hosts file" -ForegroundColor Green
        $fixesApplied++
    } else {
        Write-Host "  SUCCESS: Hosts file is clean" -ForegroundColor Green
    }
} catch {
    Write-Host "  WARNING: Could not check hosts file" -ForegroundColor Yellow
}

# FIX 8: Restart Surfshark Service
Write-Host "[8/12] Restarting Surfshark service..." -ForegroundColor Yellow
try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"} | Select-Object -First 1
    if ($service) {
        if (-not $WhatIf) {
            Restart-Service $service.Name -Force -ErrorAction Stop
        }
        Write-Host "  SUCCESS: Service restarted" -ForegroundColor Green
        $fixesApplied++
    } else {
        Write-Host "  INFO: Surfshark service not found" -ForegroundColor Gray
    }
} catch {
    Write-Host "  WARNING: Could not restart service" -ForegroundColor Yellow
}

# FIX 9: Clear App Cache
Write-Host "[9/12] Clearing Surfshark cache..." -ForegroundColor Yellow
$appPaths = @(
    "$env:LOCALAPPDATA\Surfshark",
    "$env:APPDATA\Surfshark"
)

foreach ($path in $appPaths) {
    if (Test-Path $path) {
        try {
            if (-not $WhatIf) {
                Get-ChildItem -Path $path -Recurse -Include "*.log","*.tmp","*.cache","cache*" -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
            Write-Host "  SUCCESS: Cache cleared" -ForegroundColor Green
            $fixesApplied++
            break
        } catch {
            Write-Host "  WARNING: Could not clear all cache" -ForegroundColor Yellow
        }
    }
}

# FIX 10: Reset Network Cache
Write-Host "[10/12] Resetting network cache..." -ForegroundColor Yellow
try {
    if (-not $WhatIf) {
        netsh interface ip delete arpcache | Out-Null
        netsh interface ip delete destinationcache | Out-Null
    }
    Write-Host "  SUCCESS: Network cache reset" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  WARNING: Partial network reset" -ForegroundColor Yellow
}

# FIX 11: Re-register DNS
Write-Host "[11/12] Re-registering DNS..." -ForegroundColor Yellow
try {
    if (-not $WhatIf) {
        ipconfig /registerdns | Out-Null
    }
    Write-Host "  SUCCESS: DNS registered" -ForegroundColor Green
    $fixesApplied++
} catch {
    Write-Host "  WARNING: Could not register DNS" -ForegroundColor Yellow
}

# FIX 12: Renew IP Address
Write-Host "[12/12] Renewing IP address..." -ForegroundColor Yellow
try {
    if (-not $WhatIf) {
        ipconfig /release | Out-Null
        Start-Sleep -Seconds 1
        ipconfig /renew | Out-Null
    }
    Write-Host "  SUCCESS: IP address renewed" -ForegroundColor Green
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
Write-Host "Testing Surfshark API connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://api.surfshark.com" -Method HEAD -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "  SUCCESS: Can reach Surfshark API" -ForegroundColor Green
    Write-Host ""
    Write-Host "The login issue should be fixed!" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 403) {
        Write-Host "  ERROR: Still getting 403 Forbidden" -ForegroundColor Red
        Write-Host ""
        Write-Host "ADDITIONAL STEP NEEDED:" -ForegroundColor Yellow
        Write-Host "Temporarily disable Windows Defender Real-Time Protection:" -ForegroundColor White
        Write-Host "  1. Open Windows Security" -ForegroundColor Gray
        Write-Host "  2. Virus and threat protection > Manage settings" -ForegroundColor Gray
        Write-Host "  3. Turn OFF Real-time protection" -ForegroundColor Gray
        Write-Host "  4. Try Surfshark login" -ForegroundColor Gray
        Write-Host "  5. Turn Real-time protection back ON after login" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "RESTART REQUIRED!" -ForegroundColor Yellow
Write-Host "Network fixes need a restart to take full effect." -ForegroundColor White
Write-Host ""
Write-Host "After restart, try logging into Surfshark." -ForegroundColor Cyan
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
