# SSoT Development Environment Setup Guide

This guide provides step-by-step instructions for setting up a complete development environment for the SSoT (Single Source of Truth) Chain-of-Trust Database System.

## Prerequisites

- Windows 10/11 (required for MT5 portable instance)
- PowerShell 5.1 or higher
- Visual Studio Code
- Git for Windows

## Setup Tasks

| # | Task | Acceptance Test |
|---|------|-----------------|
| **0. Git Repository Setup** | | |
| 0.1 | Initialise a new Git repository named `SSoT` and push an empty `main` branch. | `git status` shows a clean working tree (`nothing to commit, working tree clean`). |
| 0.2 | Add `.gitignore` covering **MQL5**, **SQLite**, compiled binaries (`*.ex5`), `.build/`, `.cache/`, and common IDE artefacts. | Running `git status` after a build shows no untracked artefacts. |
| 2.3 | Test compilation with MetaEditor64.exe using `/compile` and `/portable` flags. | A simple MQ5 file compiles successfully to EX5 without errors. |
| **3. VS Code Workspace Configuration** | | |
| 3.1 | Create `.vscode/settings.json` with MQL5 file associations and editor settings. | MQL5 files open with proper syntax highlighting and IntelliSense. |
| 3.2 | Create `.vscode/tasks.json` with compilation, build, and testing tasks. | All three tasks (`Compile current MQ5`, `Compile all MQ5 files`, `Run Strategy Tester`) execute successfully. |
| 3.3 | Configure MQL5 problem matcher for error detection and navigation. | Compilation errors appear in VS Code Problems panel with clickable navigation. |
| **4. Build System Setup** | | |
| 4.1 | Copy the enhanced compilation script to `build/compile.ps1`. | Script executes without errors and compiles MQ5 files correctly. |
| 4.2 | Set PowerShell execution policy for the workspace. | `build/compile.ps1` can be executed without permission errors. |
| 4.3 | Test batch compilation of all Expert Advisors. | All MQ5 files in `Experts/` compile successfully with detailed logging. |
| **5. SSoT System Integration** | | |
| 5.1 | Copy `SSoT.mq5` to `mt5/MQL5/Experts/SSoT.mq5`. | Expert Advisor appears in MT5 Navigator under Expert Advisors. |
| 5.2 | Copy `TestPanel_Simple.mqh` to `mt5/MQL5/Include/SSoT/TestPanel_Simple.mqh`. | Include file is accessible for compilation and IntelliSense. |
| 5.3 | Copy database setup scripts to workspace root. | SQL scripts are present and ready for database initialization. |
| **6. Environment Variables and Configuration** | | |
| 6.1 | Set `MT5_ROOT` environment variable pointing to `mt5/` directory. | Variable is accessible in PowerShell: `$env:MT5_ROOT` returns correct path. |
| 6.2 | Add `mt5/` directory to system PATH for global access to MT5 executables. | `terminal64.exe` and `MetaEditor64.exe` can be launched from any directory. |
| 6.3 | Configure VS Code workspace settings for relative path resolution. | File paths in tasks and settings resolve correctly regardless of workspace location. |
| **7. Acceptance Testing** | | |
| 7.1 | Compile SSoT.mq5 using VS Code task (`Ctrl+Shift+P` → `Tasks: Run Task` → `Compile current MQ5`). | Compilation succeeds and `SSoT.ex5` is generated in `mt5/MQL5/Experts/`. |
| 7.2 | Launch MT5 Strategy Tester using VS Code task. | MT5 opens in Strategy Tester mode with SSoT EA available for selection. |
| 7.3 | Run database setup scripts to create the 3-database architecture. | All three databases (input, output, sandbox) are created and accessible. |
| 7.4 | Execute a basic SSoT test run with TestPanel gold standard interface. | EA loads, displays control panel, and executes basic chain-of-trust operations. |

## Detailed Setup Instructions

### 0. Git Repository Setup

#### 0.1 Initialize Git Repository
```powershell
# Navigate to your development directory
cd C:\Development  # or your preferred location

# Create and initialize the SSoT repository
mkdir SSoT
cd SSoT
git init
git checkout -b main

# Create initial commit with empty README
echo "# SSoT Chain-of-Trust Database System" > README.md
git add README.md
git commit -m "Initial commit: SSoT project setup"

# Add remote origin (replace with your repository URL)
git remote add origin https://github.com/yourusername/SSoT.git
git push -u origin main
```

#### 0.2 Create .gitignore
Create `.gitignore` with the following content:

```gitignore
# MQL5 compiled files
*.ex5
*.ex4

# Build directories
.build/
.cache/
build/logs/

# SQLite databases (except schema files)
*.db
*.sqlite
*.sqlite3
!schema.sql
!*_structure.sql

# MetaTrader runtime files
mt5/Bases/
mt5/Config/
mt5/logs/
mt5/Profiles/
mt5/Tester/
mt5/temp/

# Keep executables for portable instance
!mt5/MetaEditor64.exe
!mt5/terminal64.exe
!mt5/metatester64.exe

# IDE and editor files
.vscode/settings.json
.vscode/launch.json
*.tmp
*.bak
*~

# Windows specific
Thumbs.db
Desktop.ini

# Logs and temporary files
*.log
npm-debug.log*

# Environment files
.env
.env.local
.env.test

# Keep only the lean SSoT.mq5 architecture
mt5/MQL5/Experts/SSoT_*.mq5
mt5/MQL5/Experts/SSoT_*.ex5
!mt5/MQL5/Experts/SSoT.mq5
```

### 1. Directory Structure Setup

#### 1.1 & 1.2 Create Core Directory Structure
```powershell
# Create main directories
mkdir build, docs, docs\Marton, mt5, src, logs

# Create MT5 MQL5 structure
mkdir mt5\MQL5\Experts, mt5\MQL5\Include\SSoT, mt5\MQL5\Files, mt5\MQL5\Logs, mt5\MQL5\Indicators, mt5\MQL5\Scripts, mt5\MQL5\Libraries

# Verify structure
tree /f
```

### 2. Portable MT5 Instance Setup

#### 2.1 Download MT5 Portable
1. Download MetaTrader 5 from MetaQuotes official website
2. Install to a temporary location
3. Copy the following files to your `mt5/` directory:
   - `terminal64.exe`
   - `MetaEditor64.exe`
   - `metatester64.exe`
   - Essential DLL files for operation

#### 2.2 & 2.3 Configure and Test MT5 Portable Mode
```powershell
# Test MT5 terminal in portable mode
.\mt5\terminal64.exe /portable

# Test MetaEditor compilation
.\mt5\MetaEditor64.exe /portable /compile:mt5\MQL5\Experts\SSoT.mq5 /log
```

### 3. VS Code Workspace Configuration

#### 3.1 Create .vscode/settings.json
```json
{
    "files.associations": {
        "*.mq5": "cpp",
        "*.mq4": "cpp", 
        "*.mqh": "cpp"
    },
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": false,
    "files.encoding": "utf8",
    "files.eol": "\r\n",
    "C_Cpp.errorSquiggles": "Disabled"
}
```

#### 3.2 Create .vscode/tasks.json
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Compile current MQ5",
            "type": "shell",
            "command": "${workspaceFolder}/mt5/MetaEditor64.exe",
            "args": [
                "/compile:${file}",
                "/portable",
                "/log"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared",
                "showReuseMessage": true,
                "clear": false
            },
            "problemMatcher": {
                "owner": "mql5",
                "fileLocation": ["relative", "${workspaceFolder}"],
                "pattern": {
                    "regexp": "^(.+)\\((\\d+),(\\d+)\\)\\s*:\\s*(error|warning|info)\\s+(\\d+)\\s*:\\s*(.+)$",
                    "file": 1,
                    "line": 2,
                    "column": 3,
                    "severity": 4,
                    "code": 5,
                    "message": 6
                }
            },
            "options": {
                "cwd": "${workspaceFolder}"
            }
        },
        {
            "label": "Compile all MQ5 files",
            "type": "shell",
            "command": "${workspaceFolder}/build/compile.ps1",
            "args": ["Experts/"],
            "group": "build",
            "options": {
                "cwd": "${workspaceFolder}/mt5/MQL5"
            }
        },
        {
            "label": "Run Strategy Tester",
            "type": "shell",
            "command": "${workspaceFolder}/mt5/terminal64.exe",
            "args": ["/test", "/portable"],
            "group": "test",
            "options": {
                "cwd": "${workspaceFolder}"
            }
        }
    ]
}
```

### 4. Build System Setup

#### 4.1 & 4.2 PowerShell Execution Policy
```powershell
# Set execution policy for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# For permanent setup (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 5. SSoT System Integration

Copy the core SSoT files:
- `SSoT.mq5` → `mt5/MQL5/Experts/SSoT.mq5`
- `TestPanel_Simple.mqh` → `mt5/MQL5/Include/SSoT/TestPanel_Simple.mqh`
- Database setup scripts to workspace root

### 6. Environment Variables (Optional)

#### 6.1 & 6.2 Set Environment Variables
```powershell
# Add to user environment variables
[Environment]::SetEnvironmentVariable("MT5_ROOT", "$PWD\mt5", "User")

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$newPath = "$currentPath;$PWD\mt5"
[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
```

### 7. Acceptance Testing

#### 7.1 Test VS Code Compilation
1. Open `SSoT.mq5` in VS Code
2. Press `Ctrl+Shift+P`, type "Tasks: Run Task"
3. Select "Compile current MQ5"
4. Verify compilation succeeds and `SSoT.ex5` is created

#### 7.2 Test Strategy Tester Launch
1. Run task "Run Strategy Tester"
2. Verify MT5 opens in portable mode
3. Confirm SSoT EA appears in Navigator

#### 7.3 & 7.4 Database and SSoT Testing
1. Run database setup scripts
2. Launch SSoT EA in Strategy Tester
3. Verify TestPanel interface loads
4. Execute basic chain-of-trust operations

## Troubleshooting

### Common Issues

1. **MetaEditor compilation fails**: Ensure `/portable` flag is used and paths are absolute
2. **VS Code tasks don't work**: Check file paths and PowerShell execution policy
3. **MT5 creates user profiles**: Verify `/portable` flag usage in all commands
4. **Include files not found**: Check that `Include/SSoT/` directory structure is correct
5. **Database access errors**: Verify SQLite databases are created and accessible

### File Permissions
If you encounter permission errors:
```powershell
# Grant full control to MT5 directory
icacls "mt5" /grant $env:USERNAME:F /t
```

### Verification Commands
```powershell
# Verify MT5 executables
Test-Path "mt5\terminal64.exe"
Test-Path "mt5\MetaEditor64.exe"

# Verify directory structure
Get-ChildItem -Recurse mt5\MQL5 | Where-Object {$_.PSIsContainer} | Select-Object FullName

# Test compilation
.\mt5\MetaEditor64.exe /portable /compile:mt5\MQL5\Experts\SSoT.mq5 /log
```

This setup guide ensures a consistent, reproducible development environment for the SSoT Chain-of-Trust Database System with full VS Code integration, portable MT5 instance, and proper build automation.
