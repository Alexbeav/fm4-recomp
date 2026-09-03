[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GameDataRoot,
    [string]$Disc2ContentRoot
)

. (Join-Path $PSScriptRoot "Release.Common.ps1")

$root = Get-Fm4RepositoryRoot
$resolvedGameRoot = Assert-Fm4GameInputs -GameDataRoot $GameDataRoot
$buildRoot = Join-Path $root ".local/work/fm4/out/build/win-amd64-release"
$executable = Join-Path $buildRoot "fm4.exe"
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw "Local build not found. Run tools/Build-Local.ps1 first."
}

Copy-Item -LiteralPath (Join-Path $root ".local/work/fm4/fm4_runtime.toml") -Destination (Join-Path $buildRoot "fm4.toml") -Force
$localUserRoot = Join-Path $root ".local/user"
[IO.Directory]::CreateDirectory($localUserRoot) | Out-Null
$arguments = @(
    "--game_data_root=$resolvedGameRoot",
    "--user_data_root=$localUserRoot"
)
if ($Disc2ContentRoot) {
    $resolvedDisc2Root = [IO.Path]::GetFullPath($Disc2ContentRoot)
    if (-not (Test-Path -LiteralPath $resolvedDisc2Root -PathType Container)) {
        throw "Disc 2 content folder not found: $resolvedDisc2Root"
    }
    $arguments += "--fm4_disc2_content_root=$resolvedDisc2Root"
}

Invoke-CheckedNative -FilePath $executable -ArgumentList $arguments -WorkingDirectory $buildRoot
