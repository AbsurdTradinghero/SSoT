# SSoT MQL5 Workspace Template

A portable VS Code workspace template for MQL5 development with the Single Source of Truth (SSoT) system.

## Prerequisites

- **Portable MT5 Installation**: You must have a portable MetaTrader 5 installation
- **VS Code**: With MQL5 syntax highlighting extensions recommended
- **PowerShell**: For build scripts (Windows)

## Quick Setup

1. **Clone this repository** into your desired workspace folder
2. **Copy your portable MT5** into the `mt5/` folder 
3. **Open the workspace** in VS Code
4. **Compile and run** using the build scripts

## Repository Structure

```
workspace/
├── .vscode/           # VS Code configuration
├── build/             # Build and compilation scripts  
├── Marton/            # Documentation
├── README.md          # This file
├── setup_pt.md        # Detailed setup guide
└── mt5/MQL5/          # Custom MQL5 code only
    ├── Experts/
    │   ├── SSoT.mq5           # Main SSoT Expert
    │   ├── DiagnosticCompile.mq5
    │   └── Legacy/            # Legacy versions
    ├── Include/SSoT/          # Custom include files
    ├── Scripts/SSoT/          # Custom scripts (if any)
    ├── Libraries/SSoT/        # Custom libraries (if any)
    └── Indicators/SSoT/       # Custom indicators (if any)
```

## What's Included

- **SSoT Expert Advisor**: Complete Single Source of Truth system
- **Test Panel Integration**: Visual debugging and database monitoring
- **VS Code Tasks**: Compilation and build automation
- **Documentation**: Complete setup and usage guides
- **Legacy Files**: Previous versions for reference

## What's NOT Included

This template only contains custom code. The following must be provided by your portable MT5:

- MT5 executable files and core installation
- Standard MQL5 includes and libraries  
- MT5 runtime files (Config, Profiles, etc.)
- Standard indicators and examples

## Usage

1. **Compilation**: Use VS Code task `Ctrl+Shift+P` → "Tasks: Run Task" → "Compile SSoT"
2. **Testing**: Attach the SSoT expert to a chart in MT5
3. **Development**: Edit source files and use the integrated test panel

## Branching Workflow

This repository is designed as a template for creating new workspace branches:

```bash
# Create new development branch
git checkout -b feature/my-new-feature

# Work on your changes
# ... edit files ...

# Commit and push
git add .
git commit -m "Add new feature"
git push origin feature/my-new-feature
```

## Support

See `Marton/` folder for complete documentation including:
- Detailed setup guide
- Compilation instructions  
- System architecture documentation
- Troubleshooting guide

---

**Template Version**: June 2025  
**MT5 Compatibility**: Build 4360+  
**License**: [Add your license here]
