# Setup Progress Tracker for SSoT Development Environment

A checklist following `Marton/Setup_Guide_Complete.md`

## 0. Git Repository Setup
- [x] 0.1 Initialize Git repository (`git init`, create `main` branch`)
- [x] 0.2 Create `.gitignore`

## 1. Directory Structure Setup
<!-- Skipped: MT5 portable instance already present, directories copied -->

## 2. Portable MT5 Instance Setup
- [x] 2.1 Download & extract MT5 portable to `mt5/`
- [x] 2.2 Configure MT5 for `/portable` mode
- [x] 2.3 Test compilation via VS Code task `Compile Current EA`

## 3. VS Code Workspace Configuration
- [x] 3.1 Create `.vscode/settings.json` (file associations, editor settings)
- [x] 3.2 `.vscode/tasks.json` created
- [x] 3.3 MQL5 problem matcher configured

## 4. Build System Setup
- [ ] 4.2 Set PowerShell execution policy for workspace
- [ ] 4.3 Test batch compilation of all EA files

## 5. SSoT System Integration
- [ ] 5.3 Add database setup scripts to root

## 6. Environment Variables & Configuration
- [ ] 6.1 Set `MT5_ROOT` env variable
- [ ] 6.2 Add `mt5/` to system `PATH`
- [ ] 6.3 Verify relative path resolution in VS Code settings

## 7. Acceptance Testing
- [ ] 7.1 Compile SSoT.mq5 via VS Code task
- [ ] 7.2 Launch MT5 Strategy Tester task
- [ ] 7.3 Run DB setup scripts (3-tier setup)
- [ ] 7.4 Execute basic chain-of-trust test run
