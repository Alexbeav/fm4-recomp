[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GameDataRoot,
    [ValidateRange(1, 64)][int]$Jobs = 2,
    [string]$SdkSourceRoot,
    [switch]$ValidateOnly
)

. (Join-Path $PSScriptRoot "Release.Common.ps1")

if (-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne "X64") {
    throw "The validated local builder currently supports Windows AMD64 only."
}

$root = Get-Fm4RepositoryRoot
$policy = Get-Fm4ReleasePolicy
& (Join-Path $PSScriptRoot "Test-RepositoryBoundary.ps1")
$resolvedGameRoot = Assert-Fm4GameInputs -GameDataRoot $GameDataRoot
$git = Resolve-Fm4Tool -Name "git"
$cmake = Resolve-Fm4Tool -Name "cmake"
$clang = Resolve-Fm4Tool -Name "clang"
$clangxx = Resolve-Fm4Tool -Name "clang++"
$ninja = Resolve-Fm4Tool -Name "ninja"
$compilerTarget = (& $clangxx -dumpmachine).Trim()
if ($LASTEXITCODE -ne 0 -or $compilerTarget -notmatch "windows-msvc$") {
    throw "Clang must target the MSVC ABI; detected target: $compilerTarget"
}

if ($ValidateOnly) {
    Write-Host "Input and toolchain validation passed. No SDK source was downloaded and no code was generated."
    return
}

$localRoot = Join-Path $root ".local"
$sdkSource = if ($SdkSourceRoot) { [IO.Path]::GetFullPath($SdkSourceRoot) } else { Join-Path $localRoot "rexglue-sdk" }
[IO.Directory]::CreateDirectory($localRoot) | Out-Null

if (-not (Test-Path -LiteralPath (Join-Path $sdkSource ".git"))) {
    if ($SdkSourceRoot) {
        throw "The supplied SDK source is not a Git checkout: $sdkSource"
    }
    if (Test-Path -LiteralPath $sdkSource) {
        throw "SDK source path exists but is not a Git checkout: $sdkSource"
    }
    Invoke-CheckedNative -FilePath $git -ArgumentList @("clone", "--no-checkout", $policy.sdk.repository, $sdkSource) -WorkingDirectory $root
    Invoke-CheckedNative -FilePath $git -ArgumentList @("checkout", "--detach", $policy.sdk.commit) -WorkingDirectory $sdkSource
    Invoke-CheckedNative -FilePath $git -ArgumentList @("submodule", "update", "--init", "--recursive") -WorkingDirectory $sdkSource
}

$sdkHead = (& $git -C $sdkSource rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $sdkHead -ne $policy.sdk.commit) {
    throw "SDK checkout is not at the required commit $($policy.sdk.commit): $sdkHead"
}
$sdkDirty = @(& $git -C $sdkSource status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0 -or $sdkDirty.Count -ne 0) {
    throw "SDK checkout has tracked modifications. Refusing a non-pinned toolchain build."
}
$submoduleStatus = @(& $git -C $sdkSource submodule status --recursive)
if ($LASTEXITCODE -ne 0 -or @($submoduleStatus | Where-Object { $_ -match "^[-+]" }).Count -ne 0) {
    throw "SDK submodules are missing or do not match the pinned SDK commit."
}

$sdkBuild = Join-Path $localRoot "sdk-build"
$sdkInstall = Join-Path $localRoot "sdk-install"
Invoke-CheckedNative -FilePath $cmake -ArgumentList @(
    "-S", $sdkSource,
    "-B", $sdkBuild,
    "-G", "Ninja Multi-Config",
    "-DCMAKE_C_COMPILER=$clang",
    "-DCMAKE_CXX_COMPILER=$clangxx",
    "-DCMAKE_MAKE_PROGRAM=$ninja",
    "-DCMAKE_C_FLAGS=-march=x86-64-v3",
    "-DCMAKE_CXX_FLAGS=-march=x86-64-v3",
    "-DCMAKE_CXX_STANDARD=23",
    "-DCMAKE_CONFIGURATION_TYPES=Release",
    "-DCMAKE_INSTALL_PREFIX=$sdkInstall"
) -WorkingDirectory $sdkSource
Invoke-CheckedNative -FilePath $cmake -ArgumentList @(
    "--build", $sdkBuild, "--config", "Release", "--target", "install", "--parallel", $Jobs
) -WorkingDirectory $sdkSource

$rexglue = Join-Path $sdkInstall "bin/rexglue.exe"
if (-not (Test-Path -LiteralPath $rexglue -PathType Leaf)) {
    throw "Pinned SDK build did not install rexglue.exe at $rexglue"
}

$projectWorkRoot = Join-Path $localRoot "work"
if (Test-Path -LiteralPath $projectWorkRoot) {
    $resolvedWorkRoot = [IO.Path]::GetFullPath($projectWorkRoot)
    if ((Split-Path -Parent $resolvedWorkRoot) -ne [IO.Path]::GetFullPath($localRoot)) {
        throw "Refusing to replace a build workspace outside .local: $resolvedWorkRoot"
    }
    Remove-Item -LiteralPath $resolvedWorkRoot -Recurse -Force
}
[IO.Directory]::CreateDirectory($projectWorkRoot) | Out-Null
$sourceAllowlist = @(Get-Content -LiteralPath (Join-Path $root $policy.source_allowlist) | ForEach-Object { $_.Trim().Replace("\", "/") } | Where-Object { $_ -and -not $_.StartsWith("#") })
foreach ($relativePath in $sourceAllowlist) {
    $source = Join-Path $root $relativePath
    $destination = Join-Path $projectWorkRoot $relativePath
    [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination
}

$fm4Root = Join-Path $projectWorkRoot "fm4"
$bootstrapRoot = Join-Path $localRoot "project-bootstrap"
if (Test-Path -LiteralPath $bootstrapRoot) {
    $resolvedBootstrapRoot = [IO.Path]::GetFullPath($bootstrapRoot)
    if ((Split-Path -Parent $resolvedBootstrapRoot) -ne [IO.Path]::GetFullPath($localRoot)) {
        throw "Refusing to replace a bootstrap workspace outside .local: $resolvedBootstrapRoot"
    }
    Remove-Item -LiteralPath $resolvedBootstrapRoot -Recurse -Force
}
Invoke-CheckedNative -FilePath $rexglue -ArgumentList @(
    "init",
    "--project-name", "fm4",
    "--xex-path", (Join-Path $resolvedGameRoot "default.xex"),
    "--game-root", $resolvedGameRoot,
    "--project-root", $bootstrapRoot
) -WorkingDirectory $root
[IO.Directory]::CreateDirectory((Join-Path $fm4Root "generated")) | Out-Null
Copy-Item -LiteralPath (Join-Path $bootstrapRoot "generated/rexglue.cmake") -Destination (Join-Path $fm4Root "generated/rexglue.cmake")
Remove-Item -LiteralPath $bootstrapRoot -Recurse -Force

$manifestTemplate = Join-Path $fm4Root "fm4_manifest.toml"
$localManifest = Join-Path $fm4Root "fm4_manifest.local.toml"
$tomlGameRoot = $resolvedGameRoot.Replace("\", "/").Replace('"', '\"')
$manifest = (Get-Content -LiteralPath $manifestTemplate -Raw).Replace("../extracted", $tomlGameRoot)
Set-Content -LiteralPath $localManifest -Value $manifest -Encoding utf8NoBOM

Invoke-CheckedNative -FilePath $rexglue -ArgumentList @("codegen", $localManifest) -WorkingDirectory $fm4Root
Invoke-CheckedNative -FilePath $cmake -ArgumentList @(
    "--preset", "win-amd64-release",
    "-DCMAKE_PREFIX_PATH=$sdkInstall",
    "-DCMAKE_C_COMPILER=$clang",
    "-DCMAKE_CXX_COMPILER=$clangxx"
) -WorkingDirectory $fm4Root
Invoke-CheckedNative -FilePath $cmake -ArgumentList @(
    "--build", "--preset", "win-amd64-release", "--parallel", $Jobs
) -WorkingDirectory $fm4Root

$buildRoot = Join-Path $fm4Root "out/build/win-amd64-release"
Copy-Item -LiteralPath (Join-Path $fm4Root "fm4_runtime.toml") -Destination (Join-Path $buildRoot "fm4.toml") -Force
$artifacts = @(
    "fm4.exe",
    "fm4_SpeechFacade_default.dll",
    "fm4_XMediaFacade_default.dll",
    "rexgpu-xenos.dll",
    "rexruntime.dll",
    "TracyClient.dll",
    "fm4.toml"
) | ForEach-Object { Join-Path $buildRoot $_ } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }

if (-not (Test-Path -LiteralPath (Join-Path $buildRoot "fm4.exe") -PathType Leaf)) {
    throw "FM4 build completed without the expected executable."
}

$projectCommit = (& $git -C $root rev-parse HEAD).Trim()
$projectDirty = @(& $git -C $root status --porcelain).Count -ne 0
$receipt = [ordered]@{
    schema_version = 1
    generated_locally = $true
    created_utc = [DateTime]::UtcNow.ToString("o")
    project_commit = $projectCommit
    project_worktree_dirty = $projectDirty
    sdk_repository = $policy.sdk.repository
    sdk_commit = $sdkHead
    game_inputs = @($policy.required_game_inputs)
    artifacts = Get-Fm4FileRecords -Paths $artifacts -BasePath $buildRoot
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $buildRoot "build-provenance.json") -Encoding utf8NoBOM

Write-Host "Local build complete: $buildRoot"
Write-Host "Run it with: pwsh -File .\tools\Run-Local.ps1 -GameDataRoot `"$resolvedGameRoot`""
