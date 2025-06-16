# Summary: Setup_Guide_Complete.md

This document outlines the end-to-end steps to initialize and configure the SSoT development environment:

- **Prerequisites**: Windows, PowerShell, VS Code, Git
- **Git Setup**: Initialize `SSoT` repo, clean `main` branch, create `.gitignore`
- **Directory Structure**: Core folders (`build`, `docs`, `mt5`, `src`, `logs`) and MT5 subfolders (`Experts`, `Include`, etc.)
- **Portable MT5**: Download/extract MT5 portable binaries, configure `/portable` mode, test compilation via MetaEditor
- **VS Code**: Create `.vscode/settings.json` (file associations, editor preferences) and `.vscode/tasks.json` (compile tasks and problem matcher)
- **Build System**: Copy and configure compilation scripts in `build/`, set execution policies, batch test compile
- **System Integration**: Copy `SSoT.mq5` and `TestPanel_Simple.mqh`, add database scripts
- **Environment Variables**: Set `MT5_ROOT`, update `PATH`, ensure relative path resolution
- **Acceptance Tests**: Compile EA, launch strategy tester, initialize databases, execute basic test flow

A comprehensive step-by-step checklist ensures a reproducible, portable, and integrated workflow.
