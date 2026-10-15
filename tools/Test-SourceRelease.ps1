[CmdletBinding()]
param(
    [ValidatePattern("^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?$")]
    [string]$Version = "0.0.0-ci"
)

. (Join-Path $PSScriptRoot "Release.Common.ps1")
$root = Get-Fm4RepositoryRoot
foreach ($script in Get-ChildItem -LiteralPath $root -Recurse -Filter *.ps1 -File) {
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors) { throw "PowerShell syntax error in $($script.FullName): $parseErrors" }
}

$first = Join-Path $root "release-out/candidate"
$temporary = Join-Path ([IO.Path]::GetTempPath()) ("fm4-ci-" + [Guid]::NewGuid().ToString("N"))
[void][IO.Directory]::CreateDirectory($temporary)
try {
    & (Join-Path $PSScriptRoot "New-SourceRelease.ps1") -Version $Version -OutputDirectory $first
    & (Join-Path $PSScriptRoot "New-SourceRelease.ps1") -Version $Version -OutputDirectory (Join-Path $temporary "second")
    $name = "fm4-recomp-source-$Version"
    $zip = Join-Path $first "$name.zip"
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    $secondHash = (Get-FileHash -LiteralPath (Join-Path $temporary "second/$name.zip") -Algorithm SHA256).Hash
    if ($hash -ne $secondHash) { throw "Source archives are not reproducible" }
    $checksum = (Get-Content -LiteralPath "$zip.sha256" -Raw).Trim()
    if ($checksum -ne "$hash  $name.zip") { throw "Checksum sidecar does not match the archive" }

    Add-Type -AssemblyName System.IO.Compression
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $expected = @(Get-Content (Join-Path $root "release/source-files.txt") | Where-Object { $_ -and -not $_.StartsWith("#") })
        $expected += "SOURCE-PROVENANCE.json"
        $actual = @($archive.Entries | ForEach-Object { $_.FullName.Substring($name.Length + 1) })
        if (@(Compare-Object ($expected | Sort-Object) ($actual | Sort-Object)).Count -ne 0) {
            throw "Archive entries do not match the source allowlist"
        }
        foreach ($entry in $archive.Entries) {
            if (-not $entry.FullName.StartsWith("$name/") -or $entry.FullName.Contains("..") -or
                $entry.LastWriteTime.Year -ne 2000) { throw "Unsafe entry or non-fixed timestamp: $($entry.FullName)" }
        }
    }
    finally { $archive.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, (Join-Path $temporary "unpacked"))
    $unpacked = Join-Path $temporary "unpacked/$name"
    & (Join-Path $unpacked "tools/Test-RepositoryBoundary.ps1")
    $receipt = Get-Content (Join-Path $unpacked "SOURCE-PROVENANCE.json") -Raw | ConvertFrom-Json
    $commit = (& git -C $root rev-parse HEAD).Trim()
    $policy = Get-Fm4ReleasePolicy
    if ($receipt.project_worktree_dirty -or $receipt.project_commit -ne $commit -or
        $receipt.sdk_commit -ne $policy.sdk.commit -or $receipt.package -ne $name) {
        throw "Source provenance does not match this clean commit and SDK pin"
    }
    if (@(Compare-Object ($expected | Where-Object { $_ -ne "SOURCE-PROVENANCE.json" } | Sort-Object) ($receipt.payload.path | Sort-Object)).Count) {
        throw "Provenance payload does not match the archive"
    }
    foreach ($record in $receipt.payload) {
        $file = Join-Path $unpacked $record.path
        if ((Get-Item $file).Length -ne $record.size -or
            (Get-FileHash $file -Algorithm SHA256).Hash -ne $record.sha256) {
            throw "Payload bytes differ from provenance: $($record.path)"
        }
    }

    # Prove the boundary rejects executable bytes even under an allowed source name.
    [IO.File]::WriteAllBytes((Join-Path $unpacked "README.md"), [byte[]](0x4D, 0x5A, 0, 0))
    $rejected = $false
    try { & (Join-Path $unpacked "tools/Test-RepositoryBoundary.ps1") }
    catch {
        if ($_.Exception.Message -notlike "*forbidden binary magic*") { throw }
        $rejected = $true
    }
    if (-not $rejected) { throw "Boundary accepted executable bytes in README.md" }
    Write-Host "Source checks passed: syntax, boundary, reproducibility, checksum, entries, provenance, payload, binary rejection."
}
finally { Remove-Item -LiteralPath $temporary -Recurse -Force }
