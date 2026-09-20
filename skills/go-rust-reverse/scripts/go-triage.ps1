#requires -Version 5

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Bin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

. (Join-Path $PSScriptRoot '..\..\scripts\lib\ToolDiscovery.ps1')

if (-not (Test-Path -LiteralPath $Bin)) {
    throw "Binary not found: $Bin"
}

$bootstrapScript = Join-Path $PSScriptRoot '..\..\scripts\bootstrap-reverse.ps1'

function Ensure-GoTool {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ManualUrl
    )

    $spec = Resolve-ReverseToolSpec -Name $Name
    if (-not $spec.Available) {
        Write-Warning "$Name not found, attempting auto-bootstrap..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript -Capability @($Name) -SkipRefresh
        if ($LASTEXITCODE -ne 0) {
            throw "Bootstrap failed for $Name. Please install manually: $ManualUrl"
        }
        $spec = Resolve-ReverseToolSpec -Name $Name
        if (-not $spec.Available) {
            throw "$Name still not available after bootstrap. Please install manually: $ManualUrl"
        }
    }
    return $spec
}

Write-Output "=== file ==="
$fileCmd = Get-FirstCommandPath -Names @('file')
if ($fileCmd) {
    & $fileCmd $Bin
}
else {
    Write-Output 'file: not installed, skipping magic identification'
}

Write-Output '=== runtime markers ==='
$stringsCmd = Get-FirstCommandPath -Names @('strings')
if ($stringsCmd) {
    $markers = & $stringsCmd $Bin | Select-String -Pattern 'go\.buildid|runtime\.main|rust_begin_unwind' | Select-Object -First 5
    if ($markers) {
        $markers | ForEach-Object { Write-Output $_.Line }
    }
    else {
        Write-Output 'no go.buildid / runtime.main / rust_begin_unwind markers'
    }
}
else {
    Write-Output 'strings: not installed, skipping marker scan'
}

$redressSpec = Ensure-GoTool -Name 'redress' -ManualUrl 'https://github.com/goretk/redress/releases'
Write-Output '=== redress info ==='
& $redressSpec.Command 'info' $Bin

Write-Output '=== redress packages ==='
& $redressSpec.Command 'packages' $Bin

$goresymSpec = Ensure-GoTool -Name 'goresym' -ManualUrl 'https://github.com/mandiant/GoReSym/releases'
Write-Output '=== GoReSym (first 60 lines) ==='
& $goresymSpec.Command $Bin | Select-Object -First 60
