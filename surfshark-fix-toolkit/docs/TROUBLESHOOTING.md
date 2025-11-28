# Troubleshooting Guide

## Common Issues and Solutions

### 🔴 "Cannot login - App could not reach Surfshark system"

**Error Message:**
```
The app could not reach Surfshark system
```

**Diagnostic Check:**
```powershell
.\Diagnose-SurfsharkIssues.ps1
```

**Likely Causes:**
1. Windows Defender blocking Surfshark
2. Firewall blocking API access
3. DNS resolution failure
4. Hosts file blocking api.surfshark.com

**Solution:**
```powershell
.\Fix-SurfsharkLogin.ps1
```

**Manual Steps (if script fails):**
1. Open Windows Security
2. **Virus & threat protection** → **Real-time protection** → Turn OFF
3. Login to Surfshark
4. Turn protection back ON
5. Add Surfshark to exclusions:
   - Windows Security → Exclusions → Add folder
   - `C:\Program Files\Surfshark\`

---

### 🔴 "Cannot connect to any VPN server"

**Error Message:**
```
Connection failed
Unable to connect to [country]
```

**Diagnostic Check:**
```powershell
Get-NetAdapter | Where-Object {$_.Name -like "*TAP*"}
```

**Likely Causes:**
1. TAP adapter disconnected/disabled
2. IPv6 conflicts
3. Hyper-V virtual adapter interference
4. Corrupted VPN protocol settings

**Solution:**
```powershell
.\Fix-SurfsharkConnection.ps1
```

**Manual TAP Adapter Fix:**
1. Open `ncpa.cpl` (Network Connections)
2. Find **"OpenVPN Data Channel Offload"** or **"TAP-Windows Adapter"**
3. Right-click → **Enable** (if disabled)
4. Right-click → **Properties** → **Internet Protocol Version 4**
5. Select **"Obtain IP address automatically"**
6. Restart Surfshark

---

### 🔴 "Execution Policy Error"

**Error Message:**
```
File cannot be loaded because running scripts is disabled on this system
```

**Solution:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

Or run with bypass:
```powershell
powershell -ExecutionPolicy Bypass -File .\Fix-SurfsharkLogin.ps1
```

---

### 🔴 "Access Denied - Administrator Required"

**Error Message:**
```
Access to the registry path is denied
```

**Solution:**
1. Close current PowerShell window
2. Press `Win + X`
3. Select **"Windows PowerShell (Admin)"**
4. Click **"Yes"** on UAC prompt
5. Re-run the script

---

### 🔴 "Fix Script Did Not Resolve Issue"

**Escalation Steps:**

#### 1. Run Diagnostic Again
```powershell
.\Diagnose-SurfsharkIssues.ps1
```
Check which test still fails.

#### 2. Try Both Fixes
```powershell
.\Fix-SurfsharkLogin.ps1
# Restart Surfshark and test
.\Fix-SurfsharkConnection.ps1
# Restart computer and test
```

#### 3. Nuclear Option
```powershell
.\Reset-NetworkStack.ps1
```
⚠️ **WARNING**: This will:
- Reset ALL network settings
- Require Surfshark reinstall
- Require computer restart

---

### 🔴 "Hyper-V Adapter Conflict Detected"

**Error Message (from diagnostic):**
```
[!] Hyper-V virtual adapter detected - may conflict with VPN
```

**Solution:**

#### Option A: Disable IPv6 (Script handles this)
```powershell
.\Fix-SurfsharkConnection.ps1
```

#### Option B: Disable Hyper-V Adapter (Manual)
1. Open `ncpa.cpl`
2. Find **"vEthernet (Default Switch)"**
3. Right-click → **Disable**
4. Restart Surfshark

#### Option C: Disable Hyper-V Completely
```powershell
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```
⚠️ Restart required. Only do this if you don't use Hyper-V.

---

### 🔴 "Internet Works, But VPN Doesn't"

**Diagnostic:**
```powershell
# Test basic internet
Test-NetConnection google.com

# Test Surfshark API
Test-NetConnection api.surfshark.com -Port 443
```

**If API fails:**
```powershell
.\Fix-SurfsharkLogin.ps1
```

**If API works but VPN fails:**
```powershell
.\Fix-SurfsharkConnection.ps1
```

---

### 🔴 "VPN Connects But No Internet"

**Likely Causes:**
- DNS leak
- Routing table issue
- Kill Switch enabled

**Solution:**
1. Disconnect VPN
2. Open Surfshark → **Settings** → **VPN settings**
3. Disable **"Kill Switch"** temporarily
4. Reconnect VPN
5. Test internet:
```powershell
Test-NetConnection google.com
```

**DNS Fix:**
```powershell
ipconfig /flushdns
ipconfig /release
ipconfig /renew
```

---

### 🔴 "Slow Connection or High Latency"

**Check current connection:**
```powershell
Test-NetConnection speedtest.net
```

**Solutions:**
1. Try different VPN protocol:
   - Surfshark → **Settings** → **VPN settings** → Protocol
   - Try **WireGuard** (fastest) or **OpenVPN UDP**

2. Connect to closer server:
   - Select server geographically closer to you

3. Check for bandwidth throttling:
   - Disconnect VPN and test speed
   - If much faster without VPN, ISP may be throttling

---

### 🔴 "Fresh Install Not Working"

**Complete Fresh Start:**

1. Uninstall Surfshark:
```powershell
Get-Package *Surfshark* | Uninstall-Package
```

2. Delete app data:
```powershell
Remove-Item -Path "$env:LOCALAPPDATA\Surfshark" -Recurse -Force
Remove-Item -Path "$env:APPDATA\Surfshark" -Recurse -Force
```

3. Reset network stack:
```powershell
.\Reset-NetworkStack.ps1
```

4. Restart computer

5. Download fresh Surfshark from [surfshark.com](https://surfshark.com)

6. Install and login

---

## Advanced Diagnostics

### Check Service Status
```powershell
Get-Service | Where-Object {$_.Name -like "*Surfshark*"}
```

Should show:
```
Status   Name               DisplayName
------   ----               -----------
Running  SurfsharkService   Surfshark Service
```

### Check Firewall Rules
```powershell
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Surfshark*"} | Format-Table
```

### Check TAP Adapter Details
```powershell
Get-NetAdapter | Where-Object {$_.Name -like "*TAP*"} | Format-List
```

### View Network Routes
```powershell
route print
```

---

## Logging for Support

If you need to contact Surfshark support, gather logs:

### System Info
```powershell
systeminfo > surfshark-systeminfo.txt
```

### Network Configuration
```powershell
ipconfig /all > surfshark-ipconfig.txt
```

### Adapter Status
```powershell
Get-NetAdapter | Format-List > surfshark-adapters.txt
```

### Firewall Rules
```powershell
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Surfshark*"} > surfshark-firewall.txt
```

---

## Still Having Issues?

### Community Support
- [GitHub Issues](../../issues) - Report bugs or ask questions
- [Surfshark Official Support](https://support.surfshark.com) - Official help

### Before Reporting
1. ✅ Run `Diagnose-SurfsharkIssues.ps1` and save output
2. ✅ Try all applicable fixes
3. ✅ Gather system logs (see above)
4. ✅ Note Windows version (`winver`)
5. ✅ Note Surfshark version (App → Settings → About)

---

## Useful Commands Reference

| Task | Command |
|------|---------|
| Test internet | `Test-NetConnection google.com` |
| Test Surfshark API | `Test-NetConnection api.surfshark.com -Port 443` |
| Flush DNS | `ipconfig /flushdns` |
| View network adapters | `Get-NetAdapter` |
| View services | `Get-Service \| Where-Object {$_.Name -like "*Surfshark*"}` |
| View firewall rules | `Get-NetFirewallRule \| Where-Object {$_.DisplayName -like "*Surfshark*"}` |
| Reset Winsock | `netsh winsock reset` |
| Reset TCP/IP | `netsh int ip reset` |
| Open network connections | `ncpa.cpl` |
| Check execution policy | `Get-ExecutionPolicy` |

---

## Prevention Tips

### Avoid Future Issues
1. ✅ Keep Windows updated
2. ✅ Keep Surfshark updated
3. ✅ Add Surfshark to antivirus exclusions
4. ✅ Don't install multiple VPNs simultaneously
5. ✅ Disable Hyper-V if not needed
6. ✅ Use recommended VPN protocol (WireGuard)

### Regular Maintenance
```powershell
# Monthly network cleanup
ipconfig /flushdns
ipconfig /release
ipconfig /renew
```

---

**[Back to README](../README.md)** | **[Installation Guide](INSTALLATION.md)** | **[FAQ](FAQ.md)**
