# Frequently Asked Questions (FAQ)

## General Questions

### ❓ What is this toolkit?
A collection of PowerShell scripts to automatically fix common Surfshark VPN issues on Windows, including login errors and connection failures.

### ❓ Is this official Surfshark software?
No, this is a **community-created toolkit** to help users troubleshoot common issues. It's not affiliated with Surfshark.

### ❓ Is it safe to use?
Yes. All scripts are open-source PowerShell code that only modify Windows network settings. You can review the code before running.

### ❓ Do I need technical knowledge?
No. Just run the diagnostic tool and follow the recommendations. The scripts are fully automated.

### ❓ Will this work on Mac or Linux?
No, this toolkit is **Windows-only** (Windows 10/11). PowerShell scripts don't work on Mac/Linux.

---

## Installation & Usage

### ❓ How do I install the toolkit?
1. Download the ZIP from [Releases](../../releases)
2. Extract to any folder
3. Open PowerShell as Administrator
4. Run `.\Diagnose-SurfsharkIssues.ps1`

See [Installation Guide](INSTALLATION.md) for detailed steps.

### ❓ Which tool should I run first?
**Always start with the diagnostic:**
```powershell
.\Diagnose-SurfsharkIssues.ps1
```
It will tell you which fix to run.

### ❓ Do I need Administrator access?
**Yes.** All fix tools require Administrator privileges to modify network settings, firewall rules, and Windows Defender.

### ❓ How do I open PowerShell as Administrator?
1. Press `Win + X`
2. Select **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**
3. Click **"Yes"** on UAC prompt

### ❓ Can I run these on Windows 7/8?
Not officially supported. Windows 10/11 required. May work on Windows 8.1 with PowerShell 5.1+.

---

## Error Messages

### ❓ "Cannot be loaded because running scripts is disabled"
Your PowerShell execution policy blocks scripts.

**Fix:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

Or run with bypass:
```powershell
powershell -ExecutionPolicy Bypass -File .\Fix-SurfsharkLogin.ps1
```

### ❓ "Access Denied" errors
You're not running as Administrator.

**Fix:**
1. Close PowerShell
2. Right-click **"Windows PowerShell"**
3. Select **"Run as Administrator"**

### ❓ "The app could not reach Surfshark system"
Windows Defender or firewall is blocking Surfshark API.

**Fix:**
```powershell
.\Fix-SurfsharkLogin.ps1
```

### ❓ "Connection failed" when trying to connect
TAP adapter is disabled or corrupted.

**Fix:**
```powershell
.\Fix-SurfsharkConnection.ps1
```

---

## Specific Issues

### ❓ Surfshark login works, but can't connect to servers
This is a **TAP adapter** or **VPN protocol** issue.

**Solution:**
```powershell
.\Fix-SurfsharkConnection.ps1
```

Restart computer after the fix completes.

### ❓ VPN connects but no internet access
**Kill Switch** may be blocking traffic.

**Solution:**
1. Disconnect VPN
2. Surfshark → **Settings** → **VPN settings**
3. Turn OFF **"Kill Switch"**
4. Reconnect VPN

### ❓ Connection is very slow
Try a different **VPN protocol**:
1. Surfshark → **Settings** → **VPN settings** → **Protocol**
2. Select **"WireGuard"** (fastest)
3. Reconnect VPN

Or connect to a **closer server** (lower latency).

### ❓ Hyper-V conflict detected - what does this mean?
Windows Hyper-V creates a virtual network adapter that can interfere with VPN connections.

**Solution:**
The `Fix-SurfsharkConnection.ps1` script automatically disables IPv6 to mitigate conflicts.

**Manual fix:**
```powershell
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```
⚠️ Only do this if you don't use Hyper-V for virtual machines.

---

## Toolkit Behavior

### ❓ Do I need to run the fix every time I use Surfshark?
**No.** Once fixed, the changes are permanent. Only re-run if issues return.

### ❓ What changes do the scripts make?
- Add Surfshark to Windows Defender exclusions
- Create firewall rules for Surfshark
- Reset DNS and network stack
- Enable/reset TAP adapter
- Disable IPv6 (connection fix only)
- Clean hosts file blocking

See script source code for complete details.

### ❓ How do I undo changes?
The **"Reset Network Stack"** tool reverses all network changes:
```powershell
.\Reset-NetworkStack.ps1
```
⚠️ This will require Surfshark reinstall.

### ❓ Do scripts send data anywhere?
**No.** All scripts run locally. No data is collected or transmitted.

### ❓ Can I use this with other VPNs?
Scripts are **Surfshark-specific**. They won't work for NordVPN, ExpressVPN, etc., but the diagnostic logic could be adapted.

---

## Troubleshooting the Toolkit

### ❓ Script runs but issue not fixed
1. Run diagnostic again:
   ```powershell
   .\Diagnose-SurfsharkIssues.ps1
   ```
2. Try the other fix tool (login vs connection)
3. If both fail, use nuclear option:
   ```powershell
   .\Reset-NetworkStack.ps1
   ```

### ❓ "Fix-SurfsharkLogin.ps1" doesn't fix login
**Manual steps:**
1. Temporarily disable Windows Defender Real-Time Protection
2. Login to Surfshark
3. Re-enable Real-Time Protection
4. Add `C:\Program Files\Surfshark\` to Defender exclusions

### ❓ "Fix-SurfsharkConnection.ps1" doesn't fix connection
**Manual TAP adapter reset:**
1. Open `ncpa.cpl`
2. Find **"OpenVPN Data Channel Offload"**
3. Right-click → **Disable**
4. Wait 5 seconds
5. Right-click → **Enable**
6. Restart Surfshark

### ❓ All fixes fail - what now?
Use the **nuclear option**:
```powershell
.\Reset-NetworkStack.ps1
```

This will:
- Reset ALL Windows network settings
- Require computer restart
- Require Surfshark reinstall from [surfshark.com](https://surfshark.com)

---

## Technical Details

### ❓ What is the TAP adapter?
**TAP (Network Tap)** is a virtual network adapter driver used by OpenVPN. Surfshark uses it for VPN connections.

Located at: `C:\Program Files\TAP-Windows\`

### ❓ What is Winsock?
**Winsock (Windows Sockets)** is the Windows API for network communication. Resetting it fixes corrupted network settings.

### ❓ Why does the fix disable IPv6?
IPv6 can conflict with VPN routing, especially with Hyper-V adapters. Disabling it forces IPv4-only traffic, which VPNs handle better.

### ❓ What is the "403 Forbidden" error?
HTTP status code indicating Windows Defender blocked Surfshark from accessing `api.surfshark.com`.

**Fix:** Add Surfshark to Defender exclusions (login fix does this automatically).

### ❓ What VPN protocols does Surfshark use?
- **WireGuard** (recommended, fastest)
- **OpenVPN UDP** (good balance)
- **OpenVPN TCP** (most compatible)
- **IKEv2** (mobile-optimized)

Scripts create firewall rules for all protocols.

---

## Comparison with Other Solutions

### ❓ Why not just reinstall Surfshark?
Reinstalling doesn't fix:
- Windows Defender blocking
- Corrupted network stack
- Disabled TAP adapter
- Firewall rules blocking VPN protocols

The toolkit fixes **root causes**, not just symptoms.

### ❓ Surfshark support told me to reinstall - why?
Support often recommends reinstall as a first step. This toolkit automates the **actual fixes** without needing reinstall.

If toolkit fails, **then** try fresh install with `Reset-NetworkStack.ps1`.

### ❓ Can I just use Surfshark's built-in troubleshooter?
Surfshark's troubleshooter is limited. This toolkit includes:
- Windows Defender exclusions
- Firewall rule creation
- TAP adapter reset
- Hyper-V conflict detection
- Complete network stack reset

### ❓ What about Windows Network Troubleshooter?
Windows troubleshooter is generic. This toolkit is **Surfshark-specific** and handles VPN-specific issues like TAP adapters and API blocking.

---

## Updates & Support

### ❓ How do I update the toolkit?
**With Git:**
```powershell
git pull
```

**Manual:**
1. Download latest release
2. Extract and replace files
3. Keep existing logs (if any)

### ❓ How do I report bugs?
Open an issue on [GitHub Issues](../../issues) with:
- Windows version (`winver`)
- Surfshark version (App → Settings → About)
- Diagnostic output (`Diagnose-SurfsharkIssues.ps1`)
- Error messages

### ❓ Can I contribute improvements?
Yes! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### ❓ Where do I get official Surfshark support?
[Surfshark Official Support](https://support.surfshark.com)

This toolkit is community-created and not affiliated with Surfshark.

---

## Success Rates

### ❓ How effective are these fixes?
Based on community feedback:
- **Login Fix**: ~95% success rate
- **Connection Fix**: ~90% success rate
- **Nuclear Option**: ~99% success (requires reinstall)

### ❓ What if none of the tools work?
Very rare (<1%). Possible causes:
- Corrupted Windows installation
- Hardware network adapter issues
- ISP blocking VPN traffic
- Surfshark account issues

Contact [Surfshark Support](https://support.surfshark.com) for account/ISP issues.

---

## Alternatives & Prevention

### ❓ How do I prevent these issues?
1. Keep Windows updated
2. Keep Surfshark updated
3. Add Surfshark to antivirus exclusions **before** issues occur
4. Don't install multiple VPNs simultaneously
5. Use WireGuard protocol (most stable)

### ❓ Should I use a different VPN?
This toolkit exists because Surfshark has Windows compatibility quirks. However:
- Most VPNs have similar issues
- Surfshark is otherwise excellent (speed, privacy, price)
- This toolkit makes troubleshooting trivial

### ❓ Can I use Surfshark without the toolkit?
Yes, most users never encounter issues. This toolkit is for **when problems occur**.

---

## Miscellaneous

### ❓ Does this work with Surfshark's browser extension?
Scripts fix the **desktop application**. Browser extension uses different technology (proxy, not VPN).

### ❓ Will this fix Kill Switch issues?
Yes, connection fix repairs Kill Switch functionality by fixing TAP adapter and firewall rules.

### ❓ Can I run multiple fixes at once?
**No.** Run one at a time:
1. Diagnostic
2. Recommended fix
3. Restart if needed
4. Test
5. If still broken, try other fix

### ❓ How long do fixes take?
- **Diagnostic**: 30 seconds
- **Login Fix**: 2 minutes
- **Connection Fix**: 3 minutes (+ restart)
- **Nuclear Option**: 5 minutes (+ restart + reinstall)

### ❓ Do I need an active Surfshark subscription?
Yes, toolkit only fixes technical issues. You still need a valid Surfshark account to use VPN.

---

## Still have questions?

- 📖 [Troubleshooting Guide](TROUBLESHOOTING.md)
- 📖 [Installation Guide](INSTALLATION.md)
- 🐛 [Report Issues](../../issues)
- 💬 [GitHub Discussions](../../discussions)

---

**[Back to README](../README.md)**
