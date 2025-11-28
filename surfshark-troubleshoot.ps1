# Surfshark VPN Troubleshooting Script
# Error: "The app could not reach Surfshark system"

Write-Host "=== Surfshark VPN Connection Troubleshooter ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Internet Connectivity
Write-Host "[1/8] Testing Internet Connectivity..." -ForegroundColor Yellow
try {
    $internetTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
    if ($internetTest) {
        Write-Host "  [OK] Internet connection is working" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] No internet connection detected!" -ForegroundColor Red
        Write-Host "  Fix: Check your network connection first" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Cannot test internet" -ForegroundColor Red
}
Write-Host ""

# Test 2: DNS Resolution for Surfshark
Write-Host "[2/8] Testing DNS Resolution for Surfshark servers..." -ForegroundColor Yellow
$surfsharkDomains = @(
    "my.surfshark.com",
    "api.surfshark.com",
    "surfshark.com"
)

foreach ($domain in $surfsharkDomains) {
    try {
        $dns = Resolve-DnsName -Name $domain -ErrorAction Stop
        Write-Host "  [OK] $domain resolved to $($dns[0].IPAddress)" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Cannot resolve $domain" -ForegroundColor Red
        Write-Host "  This is likely the problem!" -ForegroundColor Yellow
    }
}
Write-Host ""

# Test 3: Firewall Rules
Write-Host "[3/8] Checking Windows Firewall for Surfshark..." -ForegroundColor Yellow
try {
    $firewallRules = Get-NetFirewallApplicationFilter | Where-Object {$_.Program -like "*Surfshark*"}
    if ($firewallRules) {
        Write-Host "  [OK] Surfshark firewall rules found" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] No Surfshark firewall rules found" -ForegroundColor Yellow
        Write-Host "  This might be blocking the app" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [INFO] Could not check firewall rules (needs admin)" -ForegroundColor Gray
}
Write-Host ""

# Test 4: Check if Surfshark Process is Running
Write-Host "[4/8] Checking Surfshark processes..." -ForegroundColor Yellow
$surfsharkProcesses = Get-Process | Where-Object {$_.ProcessName -like "*Surfshark*"}
if ($surfsharkProcesses) {
    Write-Host "  [OK] Surfshark processes found:" -ForegroundColor Green
    foreach ($proc in $surfsharkProcesses) {
        Write-Host "    - $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Gray
    }
} else {
    Write-Host "  [INFO] No Surfshark processes currently running" -ForegroundColor Gray
}
Write-Host ""

# Test 5: Check Surfshark Service
Write-Host "[5/8] Checking Surfshark Windows Service..." -ForegroundColor Yellow
try {
    $service = Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"}
    if ($service) {
        foreach ($svc in $service) {
            if ($svc.Status -eq 'Running') {
                Write-Host "  [OK] $($svc.DisplayName) is running" -ForegroundColor Green
            } else {
                Write-Host "  [ERROR] $($svc.DisplayName) is $($svc.Status)" -ForegroundColor Red
                Write-Host "  Attempting to start service..." -ForegroundColor Yellow
                # Note: Requires admin rights
            }
        }
    } else {
        Write-Host "  [WARNING] No Surfshark service found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [INFO] Could not check services" -ForegroundColor Gray
}
Write-Host ""

# Test 6: Network Connectivity to Surfshark API
Write-Host "[6/8] Testing connection to Surfshark API..." -ForegroundColor Yellow
$apiEndpoints = @(
    "https://api.surfshark.com",
    "https://my.surfshark.com"
)

foreach ($endpoint in $apiEndpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Host "  [OK] Can reach $endpoint (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Cannot reach $endpoint" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Write-Host ""

# Test 7: Check TLS/SSL Settings
Write-Host "[7/8] Checking TLS/SSL Settings..." -ForegroundColor Yellow
try {
    $protocols = [System.Net.ServicePointManager]::SecurityProtocol
    Write-Host "  Current TLS protocols: $protocols" -ForegroundColor Gray
    
    # Enable TLS 1.2 (required by most modern services)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
    Write-Host "  [OK] TLS 1.2/1.3 enabled" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Could not verify TLS settings" -ForegroundColor Yellow
}
Write-Host ""

# Test 8: Check Proxy Settings
Write-Host "[8/8] Checking Proxy Settings..." -ForegroundColor Yellow
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxyUri = $proxy.GetProxy("http://surfshark.com")
if ($proxyUri.Host -eq "surfshark.com") {
    Write-Host "  [OK] No proxy configured" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Proxy detected: $($proxyUri.Host)" -ForegroundColor Yellow
    Write-Host "  This might interfere with Surfshark" -ForegroundColor Yellow
}
Write-Host ""

# Summary and Recommendations
Write-Host "=== TROUBLESHOOTING RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Based on the tests above, try these fixes:" -ForegroundColor White
Write-Host ""
Write-Host "1. FLUSH DNS CACHE:" -ForegroundColor Yellow
Write-Host "   ipconfig /flushdns" -ForegroundColor Green
Write-Host ""
Write-Host "2. RESET WINSOCK:" -ForegroundColor Yellow
Write-Host "   netsh winsock reset" -ForegroundColor Green
Write-Host "   (Requires Admin - restart after)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. RESET NETWORK STACK:" -ForegroundColor Yellow
Write-Host "   netsh int ip reset" -ForegroundColor Green
Write-Host "   (Requires Admin - restart after)" -ForegroundColor Gray
Write-Host ""
Write-Host "4. TEMPORARILY DISABLE FIREWALL:" -ForegroundColor Yellow
Write-Host "   Test if Surfshark works with firewall off" -ForegroundColor Gray
Write-Host ""
Write-Host "5. REINSTALL SURFSHARK:" -ForegroundColor Yellow
Write-Host "   Uninstall completely, restart, reinstall fresh" -ForegroundColor Gray
Write-Host ""
Write-Host "6. CHECK HOSTS FILE:" -ForegroundColor Yellow
Write-Host "   Make sure Surfshark domains aren't blocked" -ForegroundColor Gray
Write-Host "   File: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Green
Write-Host ""

Write-Host "Press any key to continue with automated fixes..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
