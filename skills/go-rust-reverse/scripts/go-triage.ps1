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

# ToolDiscovery.ps1 exposes the tool catalog but no command-path helper, so
# resolve commands locally. Bootstrap prefers pwsh, then Windows PowerShell.
function Get-GoTriageCommandPath {
    param(
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    foreach ($candidate in $Names) {
        $resolved = Get-Command -Name $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $resolved -and -not [string]::IsNullOrWhiteSpace([string]$resolved.Source)) {
            return [string]$resolved.Source
        }
    }
    return $null
}

function Ensure-GoTool {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ManualUrl
    )

    $spec = Resolve-ReverseToolSpec -Name $Name
    if (-not $spec.Available) {
        Write-Warning "$Name not found, attempting auto-bootstrap..."
        $launcher = Get-GoTriageCommandPath -Names @('pwsh', 'pwsh.exe', 'powershell.exe', 'powershell')
        if (-not $launcher) {
            throw "Bootstrap failed for ${Name}: no pwsh or powershell.exe launcher found. Please install manually: ${ManualUrl}"
        }
        & $launcher -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript -Capability @($Name) -SkipRefresh
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

function Test-GoTriageRuntimeMarkers {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Lines
    )

    # Classify from the already-collected marker lines. Go markers win over
    # the rust_begin_unwind string when both are present; no markers at all
    # (e.g. a stripped binary) keeps isRust false so the Go tools run.
    if ($null -eq $Lines) {
        return $false
    }
    $hasGoMarker = $false
    $hasRustMarker = $false
    foreach ($line in @($Lines)) {
        $text = [string]$line.Line
        if ($text -match 'go\.buildid|runtime\.main') {
            $hasGoMarker = $true
        }
        if ($text -match 'rust_begin_unwind') {
            $hasRustMarker = $true
        }
    }
    if ($hasGoMarker) {
        return $false
    }
    return $hasRustMarker
}

Write-Output "=== file ==="
$fileCmd = Get-GoTriageCommandPath -Names @('file')
if ($fileCmd) {
    & $fileCmd $Bin
}
else {
    Write-Output 'file: not installed, skipping magic identification'
}

Write-Output '=== runtime markers ==='
$stringsCmd = Get-GoTriageCommandPath -Names @('strings')
$markerLines = $null
if ($stringsCmd) {
    # Materialize all matches before selecting the display prefix, so the
    # native strings process is not cut off by Select-Object.
    $allMarkerLines = @(& $stringsCmd $Bin | Select-String -Pattern 'go\.buildid|runtime\.main|rust_begin_unwind')
    if ($allMarkerLines.Count -gt 0) {
        $markerLines = $allMarkerLines
        $markerLines | Select-Object -First 5 | ForEach-Object { Write-Output $_.Line }
    }
    else {
        Write-Output 'no go.buildid / runtime.main / rust_begin_unwind markers'
    }
}
else {
    Write-Output 'strings: not installed, skipping marker scan'
}

# Classify before any Go-tool bootstrap: redress and GoReSym parse Go build
# metadata and misreport Rust binaries, so they run only for non-Rust inputs.
$isRust = Test-GoTriageRuntimeMarkers -Lines $markerLines

if (-not $isRust) {
    $redressSpec = Ensure-GoTool -Name 'redress' -ManualUrl 'https://github.com/goretk/redress/releases'
    Write-Output '=== redress info ==='
    & $redressSpec.Command 'info' $Bin

    Write-Output '=== redress packages ==='
    & $redressSpec.Command 'packages' '--std' '--vendor' $Bin

    $goresymSpec = Ensure-GoTool -Name 'goresym' -ManualUrl 'https://github.com/mandiant/GoReSym/releases'
    Write-Output '=== GoReSym (first 60 lines) ==='
    & $goresymSpec.Command $Bin | Select-Object -First 60
}
else {
    Write-Warning 'Skipping redress/GoReSym: Rust runtime detected, Go-only tools not applicable'
}
