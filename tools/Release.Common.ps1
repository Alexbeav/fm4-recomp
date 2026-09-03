Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Fm4RepositoryRoot {
    return [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
}

function Get-Fm4ReleasePolicy {
    $root = Get-Fm4RepositoryRoot
    $path = Join-Path $root "release/release-policy.json"
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function Invoke-CheckedNative {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter()][string[]]$ArgumentList = @(),
        [Parameter()][string]$WorkingDirectory = (Get-Location).Path
    )

    Push-Location -LiteralPath $WorkingDirectory
    try {
        & $FilePath @ArgumentList
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE`: $FilePath $($ArgumentList -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Resolve-Fm4Tool {
    param([Parameter(Mandatory)][string]$Name)

    if ($Name -in @("clang", "clang++")) {
        $candidate = Join-Path $env:ProgramFiles "LLVM/bin/$Name.exe"
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    throw "Required tool not found: $Name"
}

function Assert-Fm4GameInputs {
    param([Parameter(Mandatory)][string]$GameDataRoot)

    $policy = Get-Fm4ReleasePolicy
    $resolvedRoot = [IO.Path]::GetFullPath($GameDataRoot)
    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
        throw "Game data folder not found: $resolvedRoot"
    }

    foreach ($inputFile in $policy.required_game_inputs) {
        $candidate = Join-Path $resolvedRoot $inputFile.path
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "Required input not found: $($inputFile.path)"
        }
        $item = Get-Item -LiteralPath $candidate
        if ($item.Length -ne [int64]$inputFile.size) {
            throw "Size mismatch for $($inputFile.path): expected $($inputFile.size), got $($item.Length)"
        }
        $actualHash = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash
        if ($actualHash -ne $inputFile.sha256) {
            throw "SHA-256 mismatch for $($inputFile.path): this dump is not the validated input"
        }
    }

    return $resolvedRoot
}

function Get-Fm4FileRecords {
    param(
        [Parameter(Mandatory)][string[]]$Paths,
        [Parameter()][string]$BasePath
    )

    return @($Paths | Sort-Object | ForEach-Object {
        $item = Get-Item -LiteralPath $_
        [ordered]@{
            path = if ($BasePath) { [IO.Path]::GetRelativePath($BasePath, $item.FullName).Replace("\", "/") } else { $item.FullName }
            size = $item.Length
            sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        }
    })
}
