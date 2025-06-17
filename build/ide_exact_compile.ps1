# IDE-Exact MQL5 Compilation Script
# This script uses the same MetaEditor64.exe compiler with identical parameters as the IDE
# Usage: powershell -ExecutionPolicy Bypass -File .\build\ide_exact_compile.ps1 "SSoT.mq5"

param(
    [Parameter(Mandatory=$true)]
    [string]$FileName,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails,
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean
)

# Set execution policy and error handling
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Continue"

# Determine workspace paths automatically
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Split-Path -Parent $ScriptDir
$MetaEditorPath = "$WorkspaceRoot\mt5\MetaEditor64.exe"
$MetaEditorLogPath = "$WorkspaceRoot\mt5\logs\metaeditor.log"
$MQL5Dir = "$WorkspaceRoot\mt5\MQL5"

Write-Host "=================================================================="
Write-Host "IDE-Exact MQL5 Compilation Script"
Write-Host "=================================================================="
Write-Host "Workspace: $WorkspaceRoot"
Write-Host "Target File: $FileName"

# Validate environment
if (-not (Test-Path $WorkspaceRoot)) {
    Write-Host "ERROR: Workspace root not found: $WorkspaceRoot" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MetaEditorPath)) {
    Write-Host "ERROR: MetaEditor not found: $MetaEditorPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MQL5Dir)) {
    Write-Host "ERROR: MQL5 directory not found: $MQL5Dir" -ForegroundColor Red
    exit 1
}

# Create logs directory if needed
$LogDir = Split-Path $MetaEditorLogPath -Parent
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    Write-Host "Created logs directory: $LogDir"
}

# Find the source file
function Find-SourceFile {
    param([string]$FileName)
    
    $SearchDirs = @(
        "$MQL5Dir\Experts",
        "$MQL5Dir\Indicators", 
        "$MQL5Dir\Scripts",
        "$MQL5Dir\Include"
    )
    
    foreach ($Dir in $SearchDirs) {
        if (Test-Path $Dir) {
            # Direct match
            $DirectPath = Join-Path $Dir $FileName
            if (Test-Path $DirectPath) {
                $DirName = Split-Path $Dir -Leaf
                Write-Host "Found '$FileName' in $DirName directory"
                return $DirectPath
            }
            
            # Recursive search
            $RecursiveFiles = Get-ChildItem -Path $Dir -Name $FileName -Recurse -ErrorAction SilentlyContinue
            if ($RecursiveFiles) {
                $FirstMatch = $RecursiveFiles | Select-Object -First 1
                $FullPath = Join-Path $Dir $FirstMatch
                Write-Host "Found '$FileName' at $($Dir.Replace($MQL5Dir, 'MQL5'))\$FirstMatch"
                return $FullPath
            }
        }
    }
    
    return $null
}

# Find the source file
$SourceFilePath = Find-SourceFile -FileName $FileName

if (-not $SourceFilePath) {
    Write-Host "ERROR: Source file not found: $FileName" -ForegroundColor Red
    
    # Show available files
    Write-Host "`nAvailable .mq5 files:"
    $AllMQ5Files = Get-ChildItem -Path $MQL5Dir -Filter "*.mq5" -Recurse | 
                   ForEach-Object { $_.FullName.Replace("$MQL5Dir\", "") } | 
                   Sort-Object
    
    foreach ($File in $AllMQ5Files) {
        Write-Host "   $File"
    }
    exit 1
}

# Define SourceLogPath and TargetFileName early, right after SourceFilePath is confirmed
$SourceLogPath = [System.IO.Path]::ChangeExtension($SourceFilePath, ".log")
$TargetFileName = [System.IO.Path]::GetFileName($SourceFilePath)

# Clean if requested
if ($Clean) {
    Write-Host "Cleaning compilation artifacts..."
    
    $Ex5File = [System.IO.Path]::ChangeExtension($SourceFilePath, ".ex5")
    if (Test-Path $Ex5File) {
        Remove-Item $Ex5File -Force
        Write-Host "   Removed: $([System.IO.Path]::GetFileName($Ex5File))"
    }
    
    if (Test-Path $MetaEditorLogPath) {
        Clear-Content $MetaEditorLogPath
        Write-Host "   Cleared compilation log"
    }
}

# Delete existing source-specific log file if it exists
if (Test-Path $SourceLogPath) {
    Write-Host "Deleting existing source log: $($SourceLogPath.Replace($WorkspaceRoot + '\\', ''))"
    Remove-Item $SourceLogPath -Force -ErrorAction SilentlyContinue
}

# Prepare exact compilation command
$RelativeFilePath = $SourceFilePath.Replace($WorkspaceRoot + "\", "")
Write-Host "`nStarting IDE-exact compilation..."
Write-Host "   File: $RelativeFilePath"
Write-Host "   Method: MetaEditor64.exe /compile /portable /log"

# Execute the EXACT compilation command that MetaEditor IDE uses
Push-Location $WorkspaceRoot
try {
    # This is the identical command used by MetaEditor IDE
    $Process = Start-Process -FilePath ".\mt5\MetaEditor64.exe" -ArgumentList "/compile:`"$RelativeFilePath`"", "/portable", "/log" -Wait -PassThru -WindowStyle Hidden
    
    # Wait for log to be written
    Start-Sleep -Seconds 1
    
    Write-Host "   Process completed with exit code: $($Process.ExitCode)"
    
} finally {
    Pop-Location
}

# Parse compilation results
Write-Host "`nParsing compilation results..."

# Check for source-specific log file first (more detailed)
if (Test-Path $SourceLogPath) {
    Write-Host "Found detailed source log: $($SourceLogPath.Replace($WorkspaceRoot + '\\', ''))"
    $SourceLogContent = Get-Content $SourceLogPath -ErrorAction SilentlyContinue
}

if (-not (Test-Path $MetaEditorLogPath)) {
    Write-Host "ERROR: MetaEditor compilation log not found: $MetaEditorLogPath" -ForegroundColor Red
    exit 1
}

# Get the most recent log entry for our file
$LogContent = Get-Content $MetaEditorLogPath -ErrorAction SilentlyContinue
$RelevantLogLines = $LogContent | Where-Object { $_ -match [regex]::Escape($TargetFileName) } | Select-Object -Last 1

if (-not $RelevantLogLines) {
    Write-Host "ERROR: No compilation result found in log for $TargetFileName" -ForegroundColor Red
    exit 1
}

$LogLine = $RelevantLogLines

# Parse the result (exact MetaEditor log format)
if ($LogLine -match "Compile.*$([regex]::Escape($TargetFileName)).*-\s*(\d+)\s+errors?,\s*(\d+)\s+warnings?") {
    $Errors = [int]$Matches[1]
    $Warnings = [int]$Matches[2]
    $Success = ($Errors -eq 0)
    
    Write-Host "`nCompilation Results:"
    Write-Host "   File: $TargetFileName"
    Write-Host "   Errors: $Errors" -ForegroundColor $(if ($Errors -eq 0) { "Green" } else { "Red" })
    Write-Host "   Warnings: $Warnings" -ForegroundColor $(if ($Warnings -eq 0) { "Green" } else { "Yellow" })
    Write-Host "   Success: $Success" -ForegroundColor $(if ($Success) { "Green" } else { "Red" })
    Write-Host "   Log: $LogLine"
    
    # Display detailed source log content if errors were found and content is available
    if ($Errors -gt 0 -and $SourceLogContent) {
        Write-Host "`nDetailed Compilation Output from $TargetFileName.log:"
        Write-Host "=================================================================="
        foreach ($Line in $SourceLogContent) {
            if ($Line -match "error|Error|ERROR") {
                Write-Host $Line -ForegroundColor Red
            } elseif ($Line -match "warning|Warning|WARNING") {
                Write-Host $Line -ForegroundColor Yellow
            } else {
                Write-Host $Line
            }
        }
        Write-Host "=================================================================="
    }
    
    # Check for generated .ex5 file
    $Ex5File = [System.IO.Path]::ChangeExtension($SourceFilePath, ".ex5")
    if ($Success -and (Test-Path $Ex5File)) {
        $Ex5Info = Get-Item $Ex5File
        Write-Host "`nGenerated Output:"
        Write-Host "   File: $([System.IO.Path]::GetFileName($Ex5File))"
        Write-Host "   Size: $($Ex5Info.Length) bytes"
        Write-Host "   Modified: $($Ex5Info.LastWriteTime)"
        
        $RelativeLocation = $Ex5Info.DirectoryName.Replace($WorkspaceRoot + "\", "")
        Write-Host "   Location: $RelativeLocation"
    }
    
    # Show detailed info if requested or errors exist
    # if (($ShowDetails -or $Errors -gt 0) -and $Errors -gt 0) {
    #     Write-Host "`nDetailed Error Analysis:" -ForegroundColor Red
    #     Write-Host "   For detailed error information:"
    #     Write-Host "      Review full log: $($SourceLogPath.Replace($WorkspaceRoot + '\\', ''))"
    # }
    
    Write-Host "`n=================================================================="
    if ($Success) {
        Write-Host "COMPILATION SUCCESSFUL" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "COMPILATION FAILED" -ForegroundColor Red
        exit 1
    }
    
} else {
    Write-Host "ERROR: Unable to parse compilation result from log line: $LogLine" -ForegroundColor Red
    exit 1
}
