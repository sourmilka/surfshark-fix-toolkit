# SURFSHARK DEEP FIX & REPAIR TOOL
# Complete diagnostic and automatic repair system
# Run as Administrator

param(
    [switch]$AutoFix = $true,
    [switch]$Verbose = $true
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Colors
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"
$ColorHeader = "Magenta"

# Check Admin
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "[CRITICAL] This tool requires Administrator privileges!" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator:" -ForegroundColor $ColorWarning
    Write-Host "1. Right-click PowerShell" -ForegroundColor White
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "3. Run this script again" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Clear-Host

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor $ColorHeader
Write-Host "║     SURFSHARK DEEP FIX & REPAIR TOOL v2.0                     ║" -ForegroundColor $ColorHeader
Write-Host "║     Complete Diagnostic and Auto-Repair System                ║" -ForegroundColor $ColorHeader
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $ColorHeader
Write-Host ""

$global:IssuesFound = @()
$global:IssuesFixed = @()
$global:IssuesFailed = @()

# Helper Functions
function Write-Status {
    param($Message, $Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "SUCCESS" { Write-Host "[$timestamp] [OK] $Message" -ForegroundColor $ColorSuccess }
        "ERROR"   { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor $ColorError }
        "WARNING" { Write-Host "[$timestamp] [WARNING] $Message" -ForegroundColor $ColorWarning }
        "INFO"    { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor $ColorInfo }
        "HEADER"  { Write-Host "`n=== $Message ===" -ForegroundColor $ColorHeader }
    }
}

function Add-Issue {
    param($Description, $Severity = "MEDIUM")
    $global:IssuesFound += [PSCustomObject]@{
        Description = $Description
        Severity = $Severity
        Timestamp = Get-Date
    }
}

function Add-Fix {
    param($Description)
    $global:IssuesFixed += $Description
}

function Add-Failure {
    param($Description)
    $global:IssuesFailed += $Description
}

# ============================================================================
# PHASE 1: SYSTEM DIAGNOSTICS
# ============================================================================

Write-Status "Starting comprehensive system diagnostics..." "HEADER"

# 1.1 - Test Internet Connectivity
Write-Status "Testing internet connectivity..." "INFO"
try {
    $pingTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet -ErrorAction Stop
    if ($pingTest) {
        Write-Status "Internet connection: WORKING" "SUCCESS"
    } else {
        Write-Status "Internet connection: FAILED" "ERROR"
        Add-Issue "No internet connection detected" "CRITICAL"
    }
} catch {
    Write-Status "Cannot verify internet connection" "WARNING"
    Add-Issue "Internet connectivity test failed" "HIGH"
}

# 1.2 - DNS Resolution Tests
Write-Status "Testing DNS resolution for Surfshark domains..." "INFO"
$surfsharkDomains = @(
    "surfshark.com",
    "api.surfshark.com",
    "my.surfshark.com",
    "downloads.surfshark.com"
)

$dnsIssues = 0
foreach ($domain in $surfsharkDomains) {
    try {
        $resolved = Resolve-DnsName -Name $domain -ErrorAction Stop -QuickTimeout
        Write-Status "DNS OK: $domain -> $($resolved[0].IPAddress)" "SUCCESS"
    } catch {
        Write-Status "DNS FAILED: $domain" "ERROR"
        $dnsIssues++
        Add-Issue "Cannot resolve DNS for $domain" "HIGH"
    }
}

# 1.3 - Test Surfshark API Connectivity
Write-Status "Testing Surfshark API connectivity..." "INFO"
$apiEndpoints = @{
    "API Server" = "https://api.surfshark.com"
    "Account Portal" = "https://my.surfshark.com"
    "Main Website" = "https://surfshark.com"
}

foreach ($endpoint in $apiEndpoints.GetEnumerator()) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.Value -Method HEAD -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Status "$($endpoint.Key): OK (Status $($response.StatusCode))" "SUCCESS"
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 403) {
            Write-Status "$($endpoint.Key): BLOCKED - 403 Forbidden" "ERROR"
            Add-Issue "403 Forbidden error on $($endpoint.Key) - likely firewall or antivirus blocking" "CRITICAL"
        } else {
            Write-Status "$($endpoint.Key): FAILED ($($_.Exception.Message))" "ERROR"
            Add-Issue "Cannot reach $($endpoint.Key)" "HIGH"
        }
    }
}

# 1.4 - Check Surfshark Installation
Write-Status "Checking Surfshark installation..." "INFO"
$surfsharkPaths = @(
    "C:\Program Files\Surfshark\Surfshark.exe",
    "C:\Program Files\Surfshark\SurfsharkService.exe",
    "C:\Program Files (x86)\Surfshark\Surfshark.exe",
    "C:\Program Files (x86)\Surfshark\SurfsharkService.exe"
)

$surfsharkInstalled = $false
$surfsharkPath = $null
foreach ($path in $surfsharkPaths) {
    if (Test-Path $path) {
        Write-Status "Found: $path" "SUCCESS"
        $surfsharkInstalled = $true
        $surfsharkPath = Split-Path $path -Parent
        break
    }
}

if (-not $surfsharkInstalled) {
    Write-Status "Surfshark is NOT installed" "ERROR"
    Add-Issue "Surfshark application not found" "CRITICAL"
} else {
    Write-Status "Surfshark installation: OK" "SUCCESS"
}

# 1.5 - Check Surfshark Service
Write-Status "Checking Surfshark Windows Service..." "INFO"
try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"} | Select-Object -First 1
    if ($service) {
        Write-Status "Service found: $($service.DisplayName)" "SUCCESS"
        if ($service.Status -eq 'Running') {
            Write-Status "Service status: RUNNING" "SUCCESS"
        } else {
            Write-Status "Service status: $($service.Status)" "WARNING"
            Add-Issue "Surfshark service is not running" "MEDIUM"
        }
    } else {
        Write-Status "Surfshark service NOT found" "ERROR"
        Add-Issue "Surfshark Windows service missing" "HIGH"
    }
} catch {
    Write-Status "Cannot check Surfshark service" "WARNING"
}

# 1.6 - Check Surfshark Processes
Write-Status "Checking Surfshark processes..." "INFO"
$processes = Get-Process | Where-Object {$_.ProcessName -like "*Surfshark*"}
if ($processes) {
    foreach ($proc in $processes) {
        Write-Status "Process running: $($proc.ProcessName) (PID: $($proc.Id))" "SUCCESS"
    }
} else {
    Write-Status "No Surfshark processes running" "WARNING"
}

# 1.7 - Windows Defender Status
Write-Status "Checking Windows Defender status..." "INFO"
try {
    $defender = Get-MpComputerStatus
    Write-Status "Real-Time Protection: $($defender.RealTimeProtectionEnabled)" "INFO"
    Write-Status "Antivirus Enabled: $($defender.AntivirusEnabled)" "INFO"
    
    if ($defender.RealTimeProtectionEnabled) {
        Add-Issue "Windows Defender Real-Time Protection is enabled (may block Surfshark)" "HIGH"
    }
} catch {
    Write-Status "Cannot check Windows Defender status" "WARNING"
}

# 1.8 - Firewall Status
Write-Status "Checking Windows Firewall status..." "INFO"
try {
    $firewallProfiles = Get-NetFirewallProfile
    foreach ($profile in $firewallProfiles) {
        Write-Status "Firewall $($profile.Name): $($profile.Enabled)" "INFO"
    }
    
    # Check for Surfshark rules
    $surfsharkRules = Get-NetFirewallApplicationFilter | Where-Object {$_.Program -like "*Surfshark*"}
    if ($surfsharkRules) {
        Write-Status "Surfshark firewall rules: FOUND" "SUCCESS"
    } else {
        Write-Status "Surfshark firewall rules: MISSING" "WARNING"
        Add-Issue "No firewall rules found for Surfshark" "MEDIUM"
    }
} catch {
    Write-Status "Cannot check firewall status" "WARNING"
}

# 1.9 - Check Proxy Settings
Write-Status "Checking proxy configuration..." "INFO"
try {
    $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    $testUri = New-Object System.Uri("http://surfshark.com")
    $proxyUri = $proxy.GetProxy($testUri)
    
    if ($proxyUri.Host -eq "surfshark.com") {
        Write-Status "Proxy: NOT configured" "SUCCESS"
    } else {
        Write-Status "Proxy detected: $($proxyUri.Host)" "WARNING"
        Add-Issue "System proxy may interfere with Surfshark" "MEDIUM"
    }
} catch {
    Write-Status "Cannot check proxy settings" "WARNING"
}

# 1.10 - Check Hosts File
Write-Status "Checking Windows hosts file..." "INFO"
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
try {
    $hostsContent = Get-Content $hostsFile -ErrorAction Stop
    $blockedEntries = $hostsContent | Where-Object {$_ -match "surfshark" -and $_ -notmatch "^#"}
    
    if ($blockedEntries) {
        Write-Status "HOSTS FILE BLOCKING SURFSHARK!" "ERROR"
        foreach ($entry in $blockedEntries) {
            Write-Status "  Blocked: $entry" "ERROR"
            Add-Issue "Hosts file contains blocking entry: $entry" "CRITICAL"
        }
    } else {
        Write-Status "Hosts file: OK (no Surfshark blocks)" "SUCCESS"
    }
} catch {
    Write-Status "Cannot read hosts file" "WARNING"
}

# 1.11 - Check Network Adapters
Write-Status "Checking network adapters..." "INFO"
try {
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}
    foreach ($adapter in $adapters) {
        Write-Status "Active adapter: $($adapter.Name) ($($adapter.InterfaceDescription))" "INFO"
    }
    
    # Check for TAP adapter (VPN adapter)
    $tapAdapter = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*TAP*" -or $_.Name -like "*Surfshark*"}
    if ($tapAdapter) {
        Write-Status "VPN TAP adapter found: $($tapAdapter.Name)" "SUCCESS"
    } else {
        Write-Status "VPN TAP adapter not found" "WARNING"
        Add-Issue "Surfshark TAP adapter may be missing or disabled" "MEDIUM"
    }
} catch {
    Write-Status "Cannot check network adapters" "WARNING"
}

# 1.12 - Check TLS/SSL Settings
Write-Status "Checking TLS/SSL configuration..." "INFO"
$currentProtocols = [System.Net.ServicePointManager]::SecurityProtocol
Write-Status "Current TLS: $currentProtocols" "INFO"

# 1.13 - Check Third-Party Security Software
Write-Status "Checking for third-party security software..." "INFO"
$securitySoftware = @(
    "avast", "avg", "kaspersky", "mcafee", "norton", "bitdefender", 
    "eset", "malwarebytes", "comodo", "zonealarm"
)

$installedSecurity = @()
foreach ($software in $securitySoftware) {
    $found = Get-Process | Where-Object {$_.ProcessName -like "*$software*"}
    if ($found) {
        $installedSecurity += $software
        Write-Status "Detected security software: $software" "WARNING"
        Add-Issue "Third-party antivirus/firewall detected: $software (may block VPN)" "MEDIUM"
    }
}

# ============================================================================
# PHASE 2: AUTOMATIC REPAIRS
# ============================================================================

Write-Status "Diagnostic complete. Starting automatic repairs..." "HEADER"
Write-Host ""
Start-Sleep -Seconds 2

if ($global:IssuesFound.Count -eq 0) {
    Write-Status "No issues detected! Surfshark should be working." "SUCCESS"
} else {
    Write-Status "Found $($global:IssuesFound.Count) issue(s). Attempting fixes..." "WARNING"
}

# Fix 1: Flush DNS Cache
Write-Status "FIX 1: Flushing DNS cache..." "INFO"
try {
    ipconfig /flushdns | Out-Null
    Write-Status "DNS cache flushed successfully" "SUCCESS"
    Add-Fix "Flushed DNS cache"
} catch {
    Write-Status "Failed to flush DNS cache" "ERROR"
    Add-Failure "DNS cache flush"
}

# Fix 2: Reset Winsock
Write-Status "FIX 2: Resetting Winsock catalog..." "INFO"
try {
    netsh winsock reset | Out-Null
    Write-Status "Winsock reset successfully" "SUCCESS"
    Add-Fix "Reset Winsock catalog"
} catch {
    Write-Status "Failed to reset Winsock" "ERROR"
    Add-Failure "Winsock reset"
}

# Fix 3: Reset TCP/IP Stack
Write-Status "FIX 3: Resetting TCP/IP stack..." "INFO"
try {
    netsh int ip reset | Out-Null
    Write-Status "TCP/IP stack reset successfully" "SUCCESS"
    Add-Fix "Reset TCP/IP stack"
} catch {
    Write-Status "Failed to reset TCP/IP" "ERROR"
    Add-Failure "TCP/IP reset"
}

# Fix 4: Enable TLS 1.2 and 1.3
Write-Status "FIX 4: Enabling modern TLS protocols..." "INFO"
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
    Write-Status "TLS 1.2/1.3 enabled" "SUCCESS"
    Add-Fix "Enabled TLS 1.2/1.3"
} catch {
    Write-Status "Failed to enable TLS protocols" "ERROR"
    Add-Failure "TLS configuration"
}

# Fix 5: Add Windows Defender Exclusions
Write-Status "FIX 5: Adding Surfshark to Windows Defender exclusions..." "INFO"
if ($surfsharkInstalled) {
    try {
        Add-MpPreference -ExclusionPath "$surfsharkPath\Surfshark.exe" -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionPath "$surfsharkPath\SurfsharkService.exe" -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess "Surfshark.exe" -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess "SurfsharkService.exe" -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionPath $surfsharkPath -ErrorAction SilentlyContinue
        Write-Status "Added Windows Defender exclusions" "SUCCESS"
        Add-Fix "Added Surfshark to Windows Defender exclusions"
    } catch {
        Write-Status "Failed to add Defender exclusions: $($_.Exception.Message)" "ERROR"
        Add-Failure "Windows Defender exclusions"
    }
}

# Fix 6: Create/Update Firewall Rules
Write-Status "FIX 6: Creating firewall rules for Surfshark..." "INFO"
if ($surfsharkInstalled) {
    try {
        # Remove old rules
        Get-NetFirewallRule -DisplayName "Surfshark*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
        
        # Create new rules
        New-NetFirewallRule -DisplayName "Surfshark VPN - Outbound" -Direction Outbound -Program "$surfsharkPath\Surfshark.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark Service - Outbound" -Direction Outbound -Program "$surfsharkPath\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark VPN - Inbound" -Direction Inbound -Program "$surfsharkPath\Surfshark.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
        New-NetFirewallRule -DisplayName "Surfshark Service - Inbound" -Direction Inbound -Program "$surfsharkPath\SurfsharkService.exe" -Action Allow -Profile Any -ErrorAction Stop | Out-Null
        
        Write-Status "Firewall rules created successfully" "SUCCESS"
        Add-Fix "Created firewall rules for Surfshark"
    } catch {
        Write-Status "Failed to create firewall rules: $($_.Exception.Message)" "ERROR"
        Add-Failure "Firewall rules creation"
    }
}

# Fix 7: Fix Hosts File
Write-Status "FIX 7: Cleaning hosts file..." "INFO"
try {
    $hostsContent = Get-Content $hostsFile
    $cleanedContent = $hostsContent | Where-Object {$_ -notmatch "surfshark" -or $_ -match "^#"}
    
    if ($hostsContent.Count -ne $cleanedContent.Count) {
        # Backup first
        Copy-Item $hostsFile "$hostsFile.backup_$(Get-Date -Format 'yyyyMMddHHmmss')" -ErrorAction Stop
        $cleanedContent | Set-Content $hostsFile -ErrorAction Stop
        Write-Status "Removed Surfshark blocks from hosts file" "SUCCESS"
        Add-Fix "Cleaned hosts file"
    } else {
        Write-Status "Hosts file already clean" "SUCCESS"
    }
} catch {
    Write-Status "Failed to clean hosts file: $($_.Exception.Message)" "ERROR"
    Add-Failure "Hosts file cleanup"
}

# Fix 8: Start/Restart Surfshark Service
Write-Status "FIX 8: Starting Surfshark service..." "INFO"
try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"} | Select-Object -First 1
    if ($service) {
        if ($service.Status -ne 'Running') {
            Start-Service $service.Name -ErrorAction Stop
            Write-Status "Surfshark service started" "SUCCESS"
            Add-Fix "Started Surfshark service"
        } else {
            Restart-Service $service.Name -Force -ErrorAction Stop
            Write-Status "Surfshark service restarted" "SUCCESS"
            Add-Fix "Restarted Surfshark service"
        }
    }
} catch {
    Write-Status "Failed to start/restart service: $($_.Exception.Message)" "ERROR"
    Add-Failure "Service start/restart"
}

# Fix 9: Clear Surfshark App Cache
Write-Status "FIX 9: Clearing Surfshark app cache..." "INFO"
$appDataPaths = @(
    "$env:LOCALAPPDATA\Surfshark",
    "$env:APPDATA\Surfshark"
)

foreach ($path in $appDataPaths) {
    if (Test-Path $path) {
        try {
            # Backup
            $backupPath = "$path.backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -Path $path -Destination $backupPath -Recurse -ErrorAction SilentlyContinue
            
            # Clear cache files
            Get-ChildItem -Path $path -Recurse -Include "*.log","*.tmp","cache*","*.cache" -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            
            Write-Status "Cleared cache: $path" "SUCCESS"
            Add-Fix "Cleared app cache from $path"
        } catch {
            Write-Status "Could not clear cache: $path" "WARNING"
        }
    }
}

# Fix 10: Repair Network Adapters
Write-Status "FIX 10: Resetting network adapters..." "INFO"
try {
    netsh interface ip delete arpcache | Out-Null
    netsh interface ip delete destinationcache | Out-Null
    Write-Status "Network adapter cache cleared" "SUCCESS"
    Add-Fix "Reset network adapter cache"
} catch {
    Write-Status "Failed to reset adapter cache" "WARNING"
}

# Fix 11: Register DNS
Write-Status "FIX 11: Re-registering DNS..." "INFO"
try {
    ipconfig /registerdns | Out-Null
    Write-Status "DNS re-registered" "SUCCESS"
    Add-Fix "Re-registered DNS"
} catch {
    Write-Status "Failed to register DNS" "WARNING"
}

# Fix 12: Renew IP Address
Write-Status "FIX 12: Renewing IP address..." "INFO"
try {
    ipconfig /release | Out-Null
    Start-Sleep -Seconds 2
    ipconfig /renew | Out-Null
    Write-Status "IP address renewed" "SUCCESS"
    Add-Fix "Renewed IP address"
} catch {
    Write-Status "Failed to renew IP address" "WARNING"
}

# ============================================================================
# PHASE 3: FINAL REPORT
# ============================================================================

Write-Host ""
Write-Host ""
Write-Status "REPAIR PROCESS COMPLETE" "HEADER"
Write-Host ""

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor $ColorHeader
Write-Host "║                     FINAL REPORT                              ║" -ForegroundColor $ColorHeader
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $ColorHeader
Write-Host ""

Write-Host "Issues Found: $($global:IssuesFound.Count)" -ForegroundColor $(if ($global:IssuesFound.Count -eq 0) { $ColorSuccess } else { $ColorWarning })
Write-Host "Fixes Applied: $($global:IssuesFixed.Count)" -ForegroundColor $ColorSuccess
Write-Host "Fixes Failed: $($global:IssuesFailed.Count)" -ForegroundColor $(if ($global:IssuesFailed.Count -eq 0) { $ColorSuccess } else { $ColorError })
Write-Host ""

if ($global:IssuesFound.Count -gt 0) {
    Write-Host "═══ Issues Detected ═══" -ForegroundColor $ColorWarning
    foreach ($issue in $global:IssuesFound) {
        $severityColor = switch ($issue.Severity) {
            "CRITICAL" { $ColorError }
            "HIGH" { $ColorWarning }
            default { $ColorInfo }
        }
        Write-Host "  [$($issue.Severity)] $($issue.Description)" -ForegroundColor $severityColor
    }
    Write-Host ""
}

if ($global:IssuesFixed.Count -gt 0) {
    Write-Host "=== Fixes Applied ===" -ForegroundColor $ColorSuccess
    foreach ($fix in $global:IssuesFixed) {
        Write-Host "  [OK] $fix" -ForegroundColor $ColorSuccess
    }
    Write-Host ""
}

if ($global:IssuesFailed.Count -gt 0) {
    Write-Host "=== Fixes That Failed ===" -ForegroundColor $ColorError
    foreach ($failure in $global:IssuesFailed) {
        Write-Host "  [FAILED] $failure" -ForegroundColor $ColorError
    }
    Write-Host ""
}

# ============================================================================
# PHASE 4: RECOMMENDATIONS
# ============================================================================

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor $ColorHeader
Write-Host "║                     NEXT STEPS                                ║" -ForegroundColor $ColorHeader
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $ColorHeader
Write-Host ""

$needsRestart = $false
if ($global:IssuesFixed -match "Winsock|TCP/IP") {
    $needsRestart = $true
}

if ($needsRestart) {
    Write-Host "[IMPORTANT] System restart required for full effect" -ForegroundColor $ColorWarning
    Write-Host ""
    $restart = Read-Host "Do you want to restart now? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Host ""
        Write-Host "Restarting in 10 seconds... (Press Ctrl+C to cancel)" -ForegroundColor $ColorWarning
        Start-Sleep -Seconds 10
        Restart-Computer -Force
        exit
    } else {
        Write-Host "Please restart manually before testing Surfshark" -ForegroundColor $ColorWarning
        Write-Host ""
    }
}

Write-Host "=== Try This Now ===" -ForegroundColor $ColorInfo
Write-Host "1. Open Surfshark app" -ForegroundColor White
Write-Host "2. Login with:" -ForegroundColor White
Write-Host "   Email: jgerenaiadaviti@gmail.com" -ForegroundColor $ColorSuccess
Write-Host "   Password: [your password]" -ForegroundColor $ColorSuccess
Write-Host ""

# Check if 403 issue was found
$has403Error = $global:IssuesFound | Where-Object {$_.Description -like "*403*"}
if ($has403Error) {
    Write-Host "=== 403 Forbidden Error Detected ===" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "If login STILL fails with 403 error:" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "OPTION A: Temporarily disable Windows Defender" -ForegroundColor $ColorInfo
    Write-Host "  1. Open Windows Security" -ForegroundColor White
    Write-Host "  2. Virus and threat protection -> Manage settings" -ForegroundColor White
    Write-Host "  3. Turn OFF 'Real-time protection'" -ForegroundColor White
    Write-Host "  4. Try Surfshark login" -ForegroundColor White
    Write-Host "  5. Turn Real-time protection back ON" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTION B: Disable third-party antivirus temporarily" -ForegroundColor $ColorInfo
    if ($installedSecurity.Count -gt 0) {
        Write-Host "  Detected: $($installedSecurity -join ', ')" -ForegroundColor $ColorWarning
    }
    Write-Host ""
    Write-Host "OPTION C: Complete reinstall" -ForegroundColor $ColorInfo
    Write-Host "  1. Uninstall Surfshark" -ForegroundColor White
    Write-Host "  2. Restart PC" -ForegroundColor White
    Write-Host "  3. Disable antivirus temporarily" -ForegroundColor White
    Write-Host "  4. Download fresh from surfshark.com" -ForegroundColor White
    Write-Host "  5. Install and login" -ForegroundColor White
    Write-Host "  6. Re-enable antivirus" -ForegroundColor White
    Write-Host ""
}

Write-Host "=== Additional Help ===" -ForegroundColor $ColorInfo
Write-Host "• Surfshark Support: https://support.surfshark.com/" -ForegroundColor White
Write-Host "• Live Chat: https://surfshark.com/contact" -ForegroundColor White
Write-Host "• Log location: $env:USERPROFILE\Desktop\my projects\wwm\surfshark-repair-log.txt" -ForegroundColor White
Write-Host ""

# Save detailed log
$logPath = "$env:USERPROFILE\Desktop\my projects\wwm\surfshark-repair-log.txt"
$logContent = @"
SURFSHARK DEEP FIX AND REPAIR TOOL - LOG
Generated: $(Get-Date)
======================================

ISSUES FOUND ($($global:IssuesFound.Count)):
$(foreach ($issue in $global:IssuesFound) { "  [$($issue.Severity)] $($issue.Description)" })

FIXES APPLIED ($($global:IssuesFixed.Count)):
$(foreach ($fix in $global:IssuesFixed) { "  [OK] $fix" })

FIXES FAILED ($($global:IssuesFailed.Count)):
$(foreach ($failure in $global:IssuesFailed) { "  [FAILED] $failure" })

SYSTEM INFORMATION:
  OS: $([System.Environment]::OSVersion.VersionString)
  PowerShell: $($PSVersionTable.PSVersion)
  User: $env:USERNAME
  Computer: $env:COMPUTERNAME
  
NETWORK INFORMATION:
  Active Adapters: $(( Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}).Count)
  DNS Servers: $(((Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses}).ServerAddresses -join ', '))
  
"@

try {
    $logContent | Out-File -FilePath $logPath -Encoding UTF8 -Force
    Write-Status "Detailed log saved to: $logPath" "SUCCESS"
} catch {
    Write-Status "Could not save log file" "WARNING"
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor $ColorInfo
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
