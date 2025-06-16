# Summary: Complete_Compilation_Guide.md

This guide covers methods for compiling MQL5 EAs within the SSoT framework:

1. **IDE-Exact Compilation Script** (`ide_exact_compile.ps1`)
   - Reproduces MetaEditor CLI parameters
   - Supports flags for detailed output and clean builds
   - Auto-detects source file, logs and parses errors for reporting

2. **VS Code Tasks Integration** (`.vscode/tasks.json`)
   - Shell tasks to compile current `.mq5` via MetaEditor64.exe
   - Keyboard-driven workflow (`Ctrl+Shift+P → Run Task`)
   - Custom problem matcher for MQL5 errors

3. **Enhanced Build Script** (`build/compile.ps1`)
   - Batch compilation for Experts, Indicators, full suite
   - Verbose and error-handling features

4. **Direct MetaEditor CLI**
   - Manual compilation commands using `/compile`, `/portable`, `/log`

The document also details a step-by-step compilation process with prerequisites checks, environment prep, verification of results, and deployment via MT5 terminal with portable mode.
