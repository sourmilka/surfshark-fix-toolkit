# Clear Surfshark App Data and Restart
# Run as Administrator

Write-Host "Stopping Surfshark processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.Name -like "*Surfshark*"} | Stop-Process -Force
Start-Sleep -Seconds 2
Write-Host "Processes stopped" -ForegroundColor Green

Write-Host "Clearing app data..." -ForegroundColor Yellow
Remove-Item "$env:LOCALAPPDATA\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Surfshark" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "App data cleared" -ForegroundColor Green

Write-Host ""
Write-Host "Starting Surfshark..." -ForegroundColor Yellow
$surfsharkPath = "C:\Program Files\Surfshark\Surfshark.exe"
if (Test-Path $surfsharkPath) {
    Start-Process $surfsharkPath
    Write-Host "Surfshark started" -ForegroundColor Green
} else {
    $surfsharkPath = "C:\Program Files (x86)\Surfshark\Surfshark.exe"
    if (Test-Path $surfsharkPath) {
        Start-Process $surfsharkPath
        Write-Host "Surfshark started" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "DONE!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now in Surfshark:" -ForegroundColor Yellow
Write-Host "1. Login with: jgerenaiadaviti@gmail.com" -ForegroundColor White
Write-Host "2. Go to Settings > VPN Settings > Protocol" -ForegroundColor White
Write-Host "3. Select: WireGuard" -ForegroundColor White
Write-Host "4. Click Quick Connect" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
