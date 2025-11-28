# Surfshark VPN Fix Toolkit - Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-11-28

### Initial Release

#### Added
- `surfshark-simple-fix.ps1` - Quick repair for login and 403 errors
- `surfshark-deep-connection-fix.ps1` - Advanced connection troubleshooting
- `surfshark-connection-fix.ps1` - TAP adapter diagnostics
- `find-game-server.ps1` - Network connection analyzer
- Comprehensive README with troubleshooting guides
- MIT License
- Contributing guidelines

#### Features
- Automatic Windows Defender exclusion setup
- Firewall rule creation for VPN protocols
- TAP adapter reset and configuration
- IPv6 conflict resolution
- Hyper-V adapter conflict detection
- DNS cache and network stack reset
- VPN protocol port testing
- Complete app data cleanup
- Service restart automation

#### Fixes
- 403 Forbidden API errors
- TAP adapter connection failures
- Hyper-V virtual adapter conflicts
- IPv6 routing issues
- DNS resolution problems
- Firewall blocking issues
- Windows Filtering Platform corruption

### Known Issues
- Requires Windows 10/11
- Must run as Administrator
- Some antivirus software may require manual exclusions
- ISP-level VPN blocking requires protocol workarounds

### Planned Features
- GUI version of repair tools
- Linux/Mac support
- Automatic protocol selection
- VPN speed testing
- Server recommendation tool
- Issue prediction and prevention
