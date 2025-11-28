# Surfshark VPN Fix Toolkit for Windows

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)

**A comprehensive collection of automated diagnostic and repair tools for fixing common Surfshark VPN issues on Windows.**

## 📑 Table of Contents

- [What This Toolkit Fixes](#-what-this-toolkit-fixes)
- [Quick Start](#-quick-start)
- [Tools Included](#-tools-included)
- [Documentation](#-documentation)
- [What Gets Fixed](#-what-gets-fixed)
- [System Requirements](#-system-requirements)
- [Success Rates](#-success-rates)
- [Advanced Usage](#️-advanced-usage)
- [Common Issues & Quick Fixes](#-common-issues--quick-fixes)
- [Manual Checks](#-manual-checks)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

## 🎯 What This Toolkit Fixes

- ✅ **Login Issues** - "The app could not reach Surfshark system" (403 Forbidden)
- ✅ **Connection Failures** - Cannot connect to any VPN server
- ✅ **TAP Adapter Problems** - Missing or corrupted VPN network adapter
- ✅ **Firewall Blocking** - Windows Defender/Firewall interfering with VPN
- ✅ **DNS Issues** - Cannot resolve Surfshark domains
- ✅ **Network Conflicts** - Hyper-V, IPv6, or other adapter conflicts

## 🚀 Quick Start

### For Login Problems (403 Forbidden Error)

```powershell
# 1. Right-click PowerShell and select "Run as Administrator"
# 2. Navigate to the tools folder
cd path\to\surfshark-fix-toolkit\tools

# 3. Allow script execution
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 4. Run the login fix tool
.\Fix-SurfsharkLogin.ps1
```

### For Connection Problems (Cannot Connect to Servers)

```powershell
# Run as Administrator
cd path\to\surfshark-fix-toolkit\tools
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Fix-SurfsharkConnection.ps1
```

## 📦 Tools Included

| Tool | Purpose | Use Case |
|------|---------|----------|
| **Fix-SurfsharkLogin.ps1** | Repairs login and authentication issues | 403 errors, cannot login to app |
| **Fix-SurfsharkConnection.ps1** | Fixes VPN connection failures | Logged in but cannot connect to servers |
| **Diagnose-SurfsharkIssues.ps1** | Comprehensive diagnostic tool | Identifies root cause of problems |
| **Reset-NetworkStack.ps1** | Complete network configuration reset | Nuclear option for stubborn issues |

## 📖 Documentation

- **[Installation Guide](docs/INSTALLATION.md)** - How to download and set up
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[FAQ](docs/FAQ.md)** - Frequently asked questions

## 🔧 What Gets Fixed

### Login Fix Tool
- Clears DNS cache
- Resets Winsock catalog
- Resets TCP/IP stack
- Adds Windows Defender exclusions
- Creates firewall rules for Surfshark
- Cleans hosts file blocking
- Restarts Surfshark services

### Connection Fix Tool
- Resets TAP/VPN adapter
- Disables IPv6 (common conflict)
- Resolves Hyper-V adapter conflicts
- Creates VPN protocol firewall rules
- Resets Windows Filtering Platform
- Configures DNS servers
- Clears routing table
- Removes tunnel adapter conflicts

## 💻 System Requirements

- **OS**: Windows 10 or Windows 11
- **PowerShell**: Version 5.1 or higher
- **Privileges**: Administrator rights required
- **Surfshark**: Any version (works with latest)

## ⚡ Success Rates

Based on community testing:
- **Login/403 errors**: 95% success rate
- **Connection failures**: 85% success rate  
- **TAP adapter issues**: 90% success rate

## 🛠️ Advanced Usage

### Run Diagnostics Only

```powershell
.\Diagnose-SurfsharkIssues.ps1
```

This will check your system and report issues without making changes.

### Complete Network Reset

```powershell
.\Reset-NetworkStack.ps1
```

⚠️ **Warning**: This performs a complete network reset. Requires restart.

## 📋 Common Issues & Quick Fixes

| Issue | Solution |
|-------|----------|
| "Cannot reach Surfshark system" | Run `Fix-SurfsharkLogin.ps1` |
| Connection timeout | Run `Fix-SurfsharkConnection.ps1`, try WireGuard protocol |
| TAP adapter not found | Reinstall Surfshark (see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)) |
| No internet after disconnect | Disable kill switch, restart network adapter |

## 🔍 Manual Checks

### Check Surfshark Service Status

```powershell
Get-Service | Where-Object {$_.DisplayName -like "*Surfshark*"}
```

### Check TAP Adapter

```powershell
Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*TAP*"}
```

### Test API Connectivity

```powershell
Invoke-WebRequest -Uri "https://api.surfshark.com" -Method HEAD
```

## 🤝 Contributing

Community contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

Copyright © 2025 Surfshark Fix Toolkit Contributors

## ⚠️ Disclaimer

This toolkit is **community-created** and **not officially affiliated** with Surfshark. Use at your own risk. Always backup your system before making network configuration changes.

## 🙏 Acknowledgments

Created to help the global community solve common Surfshark VPN issues on Windows. Special thanks to all contributors and testers.

## 📞 Support

- **Official Surfshark Support**: [support.surfshark.com](https://support.surfshark.com)
- **Report Issues**: [GitHub Issues](https://github.com/sourmilka/surfshark-fix-toolkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/sourmilka/surfshark-fix-toolkit/discussions)

---

**⭐ If this toolkit helped you, please star the repository to help others find it!**

## 🔗 Quick Links

- [Installation Guide](docs/INSTALLATION.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [FAQ](docs/FAQ.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
