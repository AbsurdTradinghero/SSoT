#
# SSoT_Analyzer Compilation Script
# Compiles the SSoT_Analyzer EA and related components
# Author: Marton (AI Engineer)
# Created: June 21, 2025
#

param(
    [string]$Configuration = "Release",
    [switch]$Verbose = $false,
    [switch]$Clean = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Define paths
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootPath = Split-Path -Parent $ScriptPath
$MT5Path = Join-Path $RootPath "MT5"
$MetaEditorPath = Join-Path $MT5Path "MetaEditor64.exe"
$MQL5Path = Join-Path $MT5Path "MQL5"
$ExpertsPath = Join-Path $MQL5Path "Experts"
$IncludePath = Join-Path $MQL5Path "Include"

Write-Host "🚀 SSoT_Analyzer Compilation Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check if MetaEditor exists
if (-not (Test-Path $MetaEditorPath)) {
    Write-Host "❌ MetaEditor64.exe not found at: $MetaEditorPath" -ForegroundColor Red
    exit 1
}

# Check if main EA file exists
$AnalyzerEAPath = Join-Path $ExpertsPath "SSoT_Analyzer.mq5"
if (-not (Test-Path $AnalyzerEAPath)) {
    Write-Host "❌ SSoT_Analyzer.mq5 not found at: $AnalyzerEAPath" -ForegroundColor Red
    exit 1
}

Write-Host "📂 Paths Configuration:" -ForegroundColor Yellow
Write-Host "   Root Path: $RootPath"
Write-Host "   MT5 Path: $MT5Path"
Write-Host "   MetaEditor: $MetaEditorPath"
Write-Host "   EA File: $AnalyzerEAPath"
Write-Host ""

# Clean previous compilation artifacts if requested
if ($Clean) {
    Write-Host "🧹 Cleaning previous compilation artifacts..." -ForegroundColor Yellow
    
    $FilesToClean = @(
        (Join-Path $ExpertsPath "SSoT_Analyzer.ex5"),
        (Join-Path $ExpertsPath "SSoT_Analyzer.log")
    )
    
    foreach ($File in $FilesToClean) {
        if (Test-Path $File) {
            Remove-Item $File -Force
            Write-Host "   Removed: $File" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# Verify include files exist
Write-Host "🔍 Verifying include files..." -ForegroundColor Yellow

$RequiredIncludes = @(
    "SSoT\Analysis\SSoTAnalysisTypes.mqh",
    "SSoT\Analysis\SSoTAnalysisEngine.mqh",
    "SSoT\Analysis\SSoTDoEasyPanel.mqh"
)

$MissingIncludes = @()
foreach ($Include in $RequiredIncludes) {
    $IncludeFullPath = Join-Path $IncludePath $Include
    if (-not (Test-Path $IncludeFullPath)) {
        Write-Host "   ❌ Missing: $Include" -ForegroundColor Red
        $MissingIncludes += $Include
    } else {
        Write-Host "   ✅ Found: $Include" -ForegroundColor Green
    }
}

if ($MissingIncludes.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Cannot compile: Missing required include files" -ForegroundColor Red
    exit 1
}

# Check DoEasy framework availability
Write-Host ""
Write-Host "🔍 Verifying DoEasy framework..." -ForegroundColor Yellow

$DoEasyPath = Join-Path $IncludePath "DoEasy"
if (-not (Test-Path $DoEasyPath)) {
    Write-Host "   ❌ DoEasy framework not found at: $DoEasyPath" -ForegroundColor Red
    Write-Host "   Please ensure DoEasy framework is properly installed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "   ✅ DoEasy framework found" -ForegroundColor Green
}

# Check critical DoEasy components
$DoEasyComponents = @(
    "Engine.mqh",
    "Objects\Graph\WForms\Containers\Panel.mqh",
    "Objects\Graph\WForms\Containers\TabControl.mqh"
)

foreach ($Component in $DoEasyComponents) {
    $ComponentPath = Join-Path $DoEasyPath $Component
    if (-not (Test-Path $ComponentPath)) {
        Write-Host "   ⚠️  DoEasy component missing: $Component" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ DoEasy component: $Component" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🔨 Starting compilation..." -ForegroundColor Cyan

# Prepare MetaEditor command arguments
$MetaEditorArgs = @(
    "/compile:$AnalyzerEAPath"
)

if ($Configuration -eq "Release") {
    $MetaEditorArgs += "/release"
} else {
    $MetaEditorArgs += "/debug"
}

if ($Verbose) {
    $MetaEditorArgs += "/verbose"
}

# Execute compilation
try {
    Write-Host "   Command: $MetaEditorPath $($MetaEditorArgs -join ' ')" -ForegroundColor Gray
    
    $Process = Start-Process -FilePath $MetaEditorPath -ArgumentList $MetaEditorArgs -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Host "✅ Compilation successful!" -ForegroundColor Green
        
        # Check if EX5 file was created
        $CompiledEAPath = Join-Path $ExpertsPath "SSoT_Analyzer.ex5"
        if (Test-Path $CompiledEAPath) {
            $FileInfo = Get-Item $CompiledEAPath
            Write-Host "   Generated: $CompiledEAPath" -ForegroundColor Green
            Write-Host "   Size: $($FileInfo.Length) bytes" -ForegroundColor Gray
            Write-Host "   Modified: $($FileInfo.LastWriteTime)" -ForegroundColor Gray
        } else {
            Write-Host "⚠️  Warning: EX5 file not found after compilation" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "❌ Compilation failed with exit code: $($Process.ExitCode)" -ForegroundColor Red
        
        # Check for compilation log
        $LogPath = Join-Path $ExpertsPath "SSoT_Analyzer.log"
        if (Test-Path $LogPath) {
            Write-Host ""
            Write-Host "📋 Compilation Log:" -ForegroundColor Yellow
            Get-Content $LogPath | ForEach-Object {
                if ($_ -match "error|failed") {
                    Write-Host "   $($_)" -ForegroundColor Red
                } elseif ($_ -match "warning") {
                    Write-Host "   $($_)" -ForegroundColor Yellow
                } else {
                    Write-Host "   $($_)" -ForegroundColor White
                }
            }
        }
        exit 1
    }
    
} catch {
    Write-Host "❌ Compilation process failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Post-compilation validation
Write-Host ""
Write-Host "🔍 Post-compilation validation..." -ForegroundColor Yellow

# Check if all expected files are present
$ExpectedFiles = @(
    (Join-Path $ExpertsPath "SSoT_Analyzer.ex5")
)

foreach ($File in $ExpectedFiles) {
    if (Test-Path $File) {
        Write-Host "   ✅ Generated: $(Split-Path -Leaf $File)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Missing: $(Split-Path -Leaf $File)" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "📊 Compilation Summary:" -ForegroundColor Cyan
Write-Host "   Configuration: $Configuration"
Write-Host "   Target: SSoT_Analyzer.mq5"
Write-Host "   Status: Success"   Write-Host "   Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Green
Write-Host "   1. Review compilation output for any warnings"
Write-Host "   2. Test the EA in MetaTrader 5"
Write-Host "   3. Verify DoEasy GUI components load correctly"
Write-Host "   4. Proceed to Phase 2 implementation"

Write-Host ""
Write-Host "✅ SSoT_Analyzer compilation completed successfully!" -ForegroundColor Green
