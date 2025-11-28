# Changelog

All notable changes to the Surfshark Fix Toolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2024-01-XX

### 🎉 Initial Release

Complete toolkit for resolving Surfshark VPN issues on Windows 10/11.

### Added

#### 🔧 Core Tools
- **Diagnose-SurfsharkIssues.ps1** - Non-invasive diagnostic tool
  - Tests internet connectivity
  - Tests DNS resolution
  - Tests Surfshark API accessibility
  - Checks Surfshark installation
  - Checks service status
  - Detects TAP adapter issues
  - Identifies firewall blocking
  - Detects Hyper-V conflicts
  - Recommends appropriate fix tool

- **Fix-SurfsharkLogin.ps1** - Login issue resolver
  - Fixes 403 Forbidden API errors
  - Resets DNS cache
  - Resets Winsock catalog
  - Adds Windows Defender exclusions
  - Creates firewall rules for Surfshark
  - Cleans hosts file blocking
  - Tests API connectivity post-fix
  - No restart required

- **Fix-SurfsharkConnection.ps1** - Connection issue resolver
  - Resets TAP adapter (OpenVPN Data Channel Offload)
  - Disables IPv6 to prevent conflicts
  - Detects Hyper-V virtual adapter interference
  - Creates VPN protocol firewall rules (WireGuard, OpenVPN)
  - Resets Windows Filtering Platform
  - Repairs network stack
  - Requires restart

- **Reset-NetworkStack.ps1** - Complete network reset (nuclear option)
  - Resets Winsock catalog
  - Resets TCP/IP stack
  - Resets Windows Firewall
  - Flushes DNS
  - Releases and renews IP
  - Resets Windows Filtering Platform
  - Disables tunnel adapters
  - Resets all network adapters
  - Clears routing table
  - Requires restart and Surfshark reinstall

#### 📖 Documentation
- **README.md** - Comprehensive project overview
  - Quick start guide
  - Tool comparison table
  - Success rate statistics
  - Requirements and compatibility
  - Issue identification flowchart
  - Troubleshooting quick reference

- **docs/INSTALLATION.md** - Complete setup guide
  - Download instructions
  - System requirements
  - PowerShell version check
  - Step-by-step usage instructions
  - Execution policy fixes
  - Firewall/antivirus handling
  - Update procedures
  - Uninstallation steps

- **docs/TROUBLESHOOTING.md** - Detailed problem-solving guide
  - Common issues and solutions
  - Error message reference
  - Escalation procedures
  - Advanced diagnostics
  - Manual fix instructions
  - Logging for support
  - Useful command reference
  - Prevention tips

- **docs/FAQ.md** - Frequently asked questions
  - 40+ common questions answered
  - General toolkit information
  - Installation and usage guidance
  - Error message explanations
  - Technical deep-dives
  - Comparison with alternatives
  - Success rates and effectiveness

- **CONTRIBUTING.md** - Contributor guidelines
  - Bug reporting template
  - Feature request process
  - Code submission workflow
  - PowerShell scripting standards
  - Documentation standards
  - Testing guidelines
  - Pull request format
  - Code of conduct

### Features

#### 🎯 Key Capabilities
- **Automated Diagnosis** - Identifies root cause in 30 seconds
- **One-Click Fixes** - Automated repair with progress indicators
- **Safe Operation** - All changes are standard Windows network settings
- **No Data Collection** - 100% local, no external communication
- **Open Source** - Full transparency, reviewable code
- **Community-Driven** - Created by users, for users

#### 🛡️ Fixes Handled
- Windows Defender blocking Surfshark API (403 errors)
- Disabled or corrupted TAP adapter
- DNS resolution failures
- Winsock catalog corruption
- IPv6 routing conflicts
- Hyper-V virtual adapter interference
- Firewall blocking VPN protocols
- Hosts file API blocking
- Network stack corruption

#### ✅ Quality Features
- PowerShell 5.1+ compatibility
- Administrator privilege enforcement
- Comprehensive error handling
- Color-coded progress indicators
- Restart prompts where needed
- Rollback via network reset tool
- No hardcoded paths
- No personal information exposure

### Technical Details

#### Compatibility
- **OS**: Windows 10 (1909+), Windows 11 (all versions)
- **PowerShell**: 5.1 or later
- **Surfshark**: All versions (desktop app)
- **Architecture**: x64 (64-bit)

#### Requirements
- Administrator privileges
- Active internet connection (for testing)
- Surfshark installed (for connection fixes)
- 10 MB free disk space

#### Network Changes Made
- Adds `C:\Program Files\Surfshark\` to Windows Defender exclusions
- Creates Windows Firewall rules:
  - Surfshark executable (all protocols)
  - WireGuard (UDP 51820)
  - OpenVPN (UDP 1194, TCP 443)
- Resets DNS cache
- Resets Winsock catalog
- May disable IPv6 (connection fix)
- May reset TAP adapter
- Cleans `C:\Windows\System32\drivers\etc\hosts`

### Known Limitations

- Windows-only (no Mac/Linux support)
- Requires Surfshark desktop app (browser extension not supported)
- Cannot fix ISP-level VPN blocking
- Cannot fix Surfshark account issues
- Cannot fix hardware network adapter failures
- Reset tool requires Surfshark reinstall

### Credits

Created by the community to help Surfshark users worldwide resolve common Windows compatibility issues.

**Special Thanks:**
- All users who reported issues and tested fixes
- Surfshark support for technical documentation
- Windows networking community for best practices

---

## [Unreleased]

### Planned Features
- GUI wrapper for non-technical users
- Automated testing framework
- Windows 11 24H2 specific optimizations
- Multi-language support
- MacOS/Linux equivalent toolkit

### Under Consideration
- Surfshark Antivirus conflict detection
- WireGuard-specific diagnostic tool
- VPN speed optimization tool
- Network latency analyzer

---

## Version History

| Version | Release Date | Major Changes |
|---------|-------------|---------------|
| 1.0.0   | 2024-01-XX  | Initial release with 4 tools and complete documentation |

---

**[Back to README](README.md)**
