# Wrapper to invoke the build script from workspace root
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TargetFile,
    [switch]$ShowDetails,
    [switch]$Clean
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildScript = Join-Path $scriptDir 'build\ide_exact_compile.ps1'

# Forward all parameters to the actual build script
& "$buildScript" $TargetFile @(if ($ShowDetails) { '-ShowDetails' }) @(if ($Clean) { '-Clean' })
