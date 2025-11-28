# Contributing to Surfshark VPN Fix Toolkit

First off, thank you for considering contributing! This toolkit helps thousands of users worldwide fix their Surfshark VPN issues.

## How Can I Contribute?

### Reporting Bugs or Issues

Found a bug? Help us improve!

1. Check if the issue already exists in [Issues](../../issues)
2. If not, create a new issue with:
   - **Clear title** describing the problem
   - **Steps to reproduce** the issue
   - **Expected behavior** vs actual behavior
   - **Your environment** (Windows version, Surfshark version)
   - **Error messages** or screenshots

### Suggesting Fixes or Improvements

Have a fix that worked for you?

1. Open an issue describing your solution
2. Include the PowerShell commands or script modifications
3. Explain when this fix should be used

### Submitting Code

1. Fork the repository
2. Create a new branch (`git checkout -b fix/your-fix-name`)
3. Make your changes
4. Test thoroughly on Windows 10/11
5. Commit with clear message (`git commit -m 'Add fix for TAP adapter issue'`)
6. Push to branch (`git push origin fix/your-fix-name`)
7. Open a Pull Request

### Code Guidelines

- **PowerShell scripts must:**
  - Include error handling
  - Provide clear user feedback
  - Check for Administrator privileges
  - Be tested on Windows 10 and 11
  - Include comments for complex operations

- **Documentation must:**
  - Be clear and concise
  - Include examples
  - Be tested by following the steps

## What We're Looking For

- Fixes for new error types
- Improved diagnostic tools
- Better error messages
- Cross-platform support (future)
- Translation to other languages
- Video tutorials or guides

## Questions?

Feel free to open an issue with the `question` label!

Thank you for helping make VPN troubleshooting easier for everyone! 🙏
