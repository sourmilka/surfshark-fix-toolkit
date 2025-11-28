# Installation Guide

## Quick Download

### Download the Toolkit
1. Visit the [Releases](../../releases) page
2. Download the latest `surfshark-fix-toolkit.zip`
3. Extract to any location (e.g., `C:\Tools\surfshark-fix-toolkit\`)

**Or clone with Git:**
```powershell
git clone https://github.com/YOUR-USERNAME/surfshark-fix-toolkit.git
cd surfshark-fix-toolkit
```

---

## Prerequisites

### System Requirements
- **OS**: Windows 10/11 (64-bit)
- **PowerShell**: Version 5.1 or later
- **Administrator Access**: Required for all fix tools

### Check Your PowerShell Version
```powershell
$PSVersionTable.PSVersion
```
Should show version 5.1 or higher.

---

## Running the Tools

### Step 1: Open PowerShell as Administrator
1. Press `Win + X`
2. Select **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**
3. Click **"Yes"** on UAC prompt

### Step 2: Navigate to Toolkit
```powershell
cd "C:\Path\To\surfshark-fix-toolkit\tools"
```

### Step 3: Run Diagnostic First
```powershell
.\Diagnose-SurfsharkIssues.ps1
```

The diagnostic will recommend which fix to run.

---

## Fix Tools Usage

### Login Issues (403 Error)
```powershell
.\Fix-SurfsharkLogin.ps1
```
- Fixes Windows Defender blocking
- Resets DNS and network settings
- Adds firewall exclusions
- Tests API connectivity

**Restart required**: No  
**Duration**: ~2 minutes

---

### Connection Issues (After Login)
```powershell
.\Fix-SurfsharkConnection.ps1
```
- Resets TAP adapter
- Disables IPv6
- Detects Hyper-V conflicts
- Repairs VPN protocols

**Restart required**: Yes  
**Duration**: ~3 minutes

---

### Nuclear Option (Last Resort)
```powershell
.\Reset-NetworkStack.ps1
```
- Complete network reset
- Clears all VPN settings
- Requires Surfshark reinstall

**Restart required**: Yes (mandatory)  
**Duration**: ~5 minutes + reinstall time

---

## Execution Policy Issues

If you see this error:
```
.\Fix-SurfsharkLogin.ps1 : File cannot be loaded because running scripts is disabled
```

**Fix:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Or run with bypass:
```powershell
powershell -ExecutionPolicy Bypass -File .\Fix-SurfsharkLogin.ps1
```

---

## Firewall/Antivirus Warnings

Some antivirus software may flag PowerShell scripts.

### Windows Defender
Scripts are safe and only modify network settings. If blocked:
1. Open Windows Security
2. **Virus & threat protection** → **Manage settings**
3. **Exclusions** → **Add exclusion** → **Folder**
4. Add `surfshark-fix-toolkit` folder

### Third-Party Antivirus
Temporarily disable or add toolkit folder to exclusions.

---

## Verifying Installation

Run the diagnostic to verify everything works:
```powershell
.\Diagnose-SurfsharkIssues.ps1
```

Expected output:
```
[✓] Internet connection: Working
[✓] DNS resolution: Working
[✓] Surfshark API: Reachable
[✓] Surfshark installation: Found
```

---

## Updating the Toolkit

### With Git
```powershell
cd surfshark-fix-toolkit
git pull
```

### Manual Download
1. Download latest release
2. Extract and replace old files
3. Keep your existing logs (if any)

---

## Uninstallation

Simply delete the toolkit folder:
```powershell
Remove-Item -Path "C:\Path\To\surfshark-fix-toolkit" -Recurse -Force
```

All changes made by the tools are Windows network settings, not specific to the toolkit.

---

## Need Help?

- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Frequently Asked Questions](FAQ.md)
- [Report Issues](../../issues)

---

## Next Steps

After installation:
1. ✅ Run `Diagnose-SurfsharkIssues.ps1`
2. ✅ Follow recommended fix
3. ✅ Test Surfshark connection
4. ✅ Check [FAQ](FAQ.md) if issues persist
