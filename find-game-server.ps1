# Find Where Winds Meet Game Server Connections
# This script identifies active network connections for the game

$gamePID = 26176
$gameName = "wwm.exe"

Write-Host "=== Where Winds Meet - Server Connection Finder ===" -ForegroundColor Cyan
Write-Host ""

# Check if process is running
$process = Get-Process -Id $gamePID -ErrorAction SilentlyContinue

if ($process) {
    Write-Host "[OK] Game Process Found:" -ForegroundColor Green
    Write-Host "    PID: $gamePID"
    Write-Host "    Name: $($process.ProcessName)"
    Write-Host ""
} else {
    Write-Host "[ERROR] Process with PID $gamePID not found!" -ForegroundColor Red
    Write-Host "    Please verify the game is running and update the PID"
    exit
}

# Get network connections for this process
Write-Host "=== Active Network Connections ===" -ForegroundColor Yellow
Write-Host ""

$connections = Get-NetTCPConnection -OwningProcess $gamePID -ErrorAction SilentlyContinue | 
    Where-Object { $_.State -eq 'Established' -and $_.RemoteAddress -notlike '127.*' -and $_.RemoteAddress -notlike '::1' }

$udpConnections = Get-NetUDPEndpoint -OwningProcess $gamePID -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalAddress -ne '127.0.0.1' -and $_.LocalAddress -ne '::1' }

if ($connections) {
    Write-Host "TCP Connections:" -ForegroundColor Cyan
    foreach ($conn in $connections) {
        Write-Host "  → Server IP: $($conn.RemoteAddress)" -ForegroundColor Green
        Write-Host "    Port: $($conn.RemotePort)"
        Write-Host "    Local Port: $($conn.LocalPort)"
        Write-Host "    State: $($conn.State)"
        
        # Try to get geographic info (basic)
        try {
            $hostname = [System.Net.Dns]::GetHostEntry($conn.RemoteAddress).HostName
            Write-Host "    Hostname: $hostname" -ForegroundColor Magenta
        } catch {
            Write-Host "    Hostname: Not resolvable" -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "  No established TCP connections found" -ForegroundColor Gray
}

if ($udpConnections) {
    Write-Host "UDP Endpoints (Game likely uses UDP):" -ForegroundColor Cyan
    foreach ($udp in $udpConnections) {
        Write-Host "  → Local Address: $($udp.LocalAddress)" -ForegroundColor Green
        Write-Host "    Local Port: $($udp.LocalPort)"
        Write-Host ""
    }
}

Write-Host ""
Write-Host "=== Wireshark Filter Commands ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "To capture game traffic in Wireshark, use these filters:" -ForegroundColor White
Write-Host ""
Write-Host "1. Display Filter (after capture):" -ForegroundColor Cyan
Write-Host '   (ip.src == YOUR_IP or ip.dst == YOUR_IP) and not icmp' -ForegroundColor Green
Write-Host ""
Write-Host "2. For specific game process:" -ForegroundColor Cyan
Write-Host "   Use this after starting capture:" -ForegroundColor Gray
if ($connections) {
    $remoteIPs = ($connections | Select-Object -ExpandProperty RemoteAddress -Unique) -join ' or ip.addr == '
    if ($remoteIPs) {
        Write-Host "   ip.addr == $remoteIPs" -ForegroundColor Green
    }
}
Write-Host ""
Write-Host "3. Common game ports filter:" -ForegroundColor Cyan
Write-Host '   udp.port >= 1024 and udp.port <= 65535' -ForegroundColor Green
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Note the server IPs shown above"
Write-Host "2. Open Wireshark and select your network adapter"
Write-Host "3. Start capture and play the game"
Write-Host "4. Stop after 30 seconds and apply filters"
Write-Host "5. Look for frequent UDP packets to identify game server"
Write-Host ""
