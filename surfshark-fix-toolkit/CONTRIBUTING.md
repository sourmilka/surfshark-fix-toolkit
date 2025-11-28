# Contributing to Surfshark Fix Toolkit

Thank you for considering contributing! This toolkit helps thousands of users worldwide resolve Surfshark VPN issues.

---

## How to Contribute

### 🐛 Report Bugs
Found a bug? [Open an issue](../../issues/new) with:
- Windows version (`winver` command)
- Surfshark version (App → Settings → About)
- PowerShell version (`$PSVersionTable.PSVersion`)
- Output from `Diagnose-SurfsharkIssues.ps1`
- Steps to reproduce
- Error messages/screenshots

### 💡 Suggest Features
Have an idea? [Open an issue](../../issues/new) with:
- Clear description of the feature
- Use case (why it's needed)
- Proposed implementation (if applicable)

### 🔧 Submit Code
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-fix`)
3. Make your changes
4. Test thoroughly (see Testing Guidelines below)
5. Commit with clear messages (`git commit -m 'Add support for XYZ'`)
6. Push to your fork (`git push origin feature/amazing-fix`)
7. Open a Pull Request

---

## Development Guidelines

### PowerShell Scripting Standards

#### Required Elements
All scripts must include:
```powershell
#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# Clear description at the top
# Version number
# Author credit (optional)
```

#### Naming Conventions
- **Files**: Use PowerShell verb-noun pattern
  - ✅ `Fix-SurfsharkLogin.ps1`
  - ✅ `Diagnose-SurfsharkIssues.ps1`
  - ❌ `surfshark-fix.ps1`
  - ❌ `LoginRepair.ps1`

- **Functions**: PascalCase with approved verbs
  - ✅ `Test-InternetConnection`
  - ✅ `Reset-TAPAdapter`
  - ❌ `check_internet`

- **Variables**: camelCase
  - ✅ `$apiEndpoint`
  - ✅ `$isConnected`
  - ❌ `$API_ENDPOINT`

#### Code Style
```powershell
# Use Write-Host with colors for user feedback
Write-Host "Starting fix..." -ForegroundColor Cyan
Write-Host "[✓] Complete" -ForegroundColor Green
Write-Host "[!] Warning" -ForegroundColor Yellow
Write-Host "[✗] Failed" -ForegroundColor Red

# Always include error handling
try {
    # Risky operation
    Some-Command
} catch {
    Write-Host "[✗] Error: $_" -ForegroundColor Red
}

# Use progress indicators
Write-Host "[1/5] Step one..." -ForegroundColor Yellow
Write-Host "[2/5] Step two..." -ForegroundColor Yellow

# Comment complex logic
# This resets the TAP adapter by disabling and re-enabling it
Get-NetAdapter | Where-Object {$_.Name -like "*TAP*"} | Disable-NetAdapter -Confirm:$false
Start-Sleep -Seconds 2
Get-NetAdapter | Where-Object {$_.Name -like "*TAP*"} | Enable-NetAdapter -Confirm:$false
```

### Documentation Standards

#### Markdown Files
- Use clear headings (`##`, `###`)
- Include table of contents for long documents
- Use code blocks with language tags
- Add emoji for visual hierarchy (✅, ❌, ⚠️, 🔧)
- Link related docs

#### Code Comments
```powershell
# Fix-SurfsharkLogin.ps1
# Resolves 403 Forbidden errors when logging into Surfshark
# Version: 1.0.0
# Requires: Administrator privileges

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# Main logic
Write-Host "Surfshark Login Fix Tool" -ForegroundColor Cyan
Write-Host "Version 1.0.0" -ForegroundColor Gray

# Step 1: Flush DNS cache
Write-Host "[1/12] Flushing DNS..." -ForegroundColor Yellow
try {
    ipconfig /flushdns | Out-Null
    Write-Host "  Complete" -ForegroundColor Green
} catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
}
```

---

## Testing Guidelines

### Before Submitting
Test your changes on:
- ✅ Fresh Windows 10 installation
- ✅ Fresh Windows 11 installation
- ✅ System with Surfshark installed
- ✅ System without Surfshark (diagnostic should detect)

### Test Cases
1. **Happy Path**: Script runs successfully
2. **No Admin**: Script exits gracefully with error message
3. **Surfshark Not Installed**: Script handles missing installation
4. **Already Fixed**: Script detects and reports "no issues found"
5. **Partial Fix**: Script continues despite some failures

### Validation Checklist
- [ ] Script requires administrator
- [ ] Clear progress indicators
- [ ] Error handling for all commands
- [ ] No hardcoded paths (use `$env:ProgramFiles`, etc.)
- [ ] No personal information (emails, usernames, passwords)
- [ ] Restarts/reboots clearly prompted
- [ ] No data sent externally
- [ ] Works on PowerShell 5.1+

---

## Pull Request Guidelines

### PR Title Format
```
[Type] Brief description

Types:
- [Fix] Bug fixes
- [Feature] New functionality
- [Docs] Documentation changes
- [Refactor] Code improvements without behavior change
- [Test] Test additions/changes
```

Examples:
- `[Fix] Resolve TAP adapter detection on Windows 11`
- `[Feature] Add WireGuard-specific firewall rules`
- `[Docs] Update FAQ with Hyper-V conflict resolution`

### PR Description Template
```markdown
## Description
Brief summary of changes

## Motivation
Why is this change needed?

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing Done
- [ ] Tested on Windows 10
- [ ] Tested on Windows 11
- [ ] Tested with Surfshark installed
- [ ] Tested without Surfshark

## Related Issues
Fixes #123
```

### Review Process
1. Automated checks (if applicable)
2. Manual code review
3. Testing on clean Windows installation
4. Approval from maintainer
5. Merge to main branch

---

## Code of Conduct

### Expected Behavior
- ✅ Be respectful and inclusive
- ✅ Provide constructive feedback
- ✅ Focus on the issue, not the person
- ✅ Help others learn

### Unacceptable Behavior
- ❌ Harassment or discrimination
- ❌ Trolling or insulting comments
- ❌ Publishing private information
- ❌ Spam or self-promotion

Violations may result in removal from the project.

---

## Project Structure

```
surfshark-fix-toolkit/
├── tools/                          # PowerShell fix scripts
│   ├── Diagnose-SurfsharkIssues.ps1   # Diagnostic tool
│   ├── Fix-SurfsharkLogin.ps1         # Login fix (403 errors)
│   ├── Fix-SurfsharkConnection.ps1    # Connection fix (TAP adapter)
│   └── Reset-NetworkStack.ps1         # Nuclear option
├── docs/                           # Documentation
│   ├── INSTALLATION.md                # Setup guide
│   ├── TROUBLESHOOTING.md            # Problem-solving guide
│   └── FAQ.md                        # Frequently asked questions
├── README.md                       # Main project overview
├── CONTRIBUTING.md                 # This file
├── LICENSE                         # MIT License
└── .gitignore                      # Git ignore rules
```

---

## Areas Needing Help

### High Priority
- 🔴 Windows 11 24H2 compatibility testing
- 🔴 Automated testing framework
- 🔴 Support for Surfshark Antivirus conflicts

### Medium Priority
- 🟡 Translations (non-English Windows support)
- 🟡 GUI wrapper for non-technical users
- 🟡 MacOS/Linux equivalent toolkit

### Low Priority
- 🟢 Performance optimizations
- 🟢 Additional diagnostic checks
- 🟢 Video tutorials

---

## Getting Help

### Developer Questions
- 💬 [GitHub Discussions](../../discussions)
- 🐛 [Issues](../../issues)

### Learning Resources
- [PowerShell Documentation](https://docs.microsoft.com/powershell)
- [Windows Network Troubleshooting](https://docs.microsoft.com/windows/networking)
- [OpenVPN TAP Adapter](https://openvpn.net/community-resources/how-to/)

---

## Recognition

Contributors will be:
- Listed in README.md credits section
- Mentioned in release notes
- Given credit in commit messages

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](../LICENSE).

---

## Questions?

Feel free to [open an issue](../../issues/new) or start a [discussion](../../discussions/new)!

---

**Thank you for making this toolkit better! 🎉**
