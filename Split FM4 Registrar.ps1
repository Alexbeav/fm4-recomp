param(
    [string]$Path = (Join-Path $PSScriptRoot "fm4\generated\default\fm4_register.cpp"),
    [ValidateRange(256, 16384)]
    [int]$ChunkSize = 4096
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Generated registrar not found: $Path"
}

$lines = [System.IO.File]::ReadAllLines($Path)
$publicFunction = -1
for ($index = 0; $index -lt $lines.Length; $index++) {
    if ($lines[$index] -match '^void fm4_RegisterFunctions\(') {
        $publicFunction = $index
        break
    }
}
if ($publicFunction -lt 0) {
    throw "Could not find fm4_RegisterFunctions in $Path"
}

$registrations = @($lines | Where-Object {
    $_ -match '^\s*registrar->SetFunction\('
})
if ($registrations.Count -lt 1) {
    throw "No SetFunction registrations found in $Path"
}

$generatedBody = $publicFunction
for ($index = 0; $index -lt $publicFunction; $index++) {
    if ($lines[$index] -eq 'namespace {') {
        $generatedBody = $index
        break
    }
}

$builder = [System.Text.StringBuilder]::new()
for ($index = 0; $index -lt $generatedBody; $index++) {
    [void]$builder.AppendLine($lines[$index])
}

[void]$builder.AppendLine('namespace {')
$chunkCount = [int][Math]::Ceiling($registrations.Count / [double]$ChunkSize)
for ($chunk = 0; $chunk -lt $chunkCount; $chunk++) {
    $name = "fm4_RegisterFunctionsChunk_{0:D3}" -f $chunk
    [void]$builder.AppendLine("__declspec(noinline) void $name(rex::runtime::IModuleRegistrar* registrar) {")
    $start = $chunk * $ChunkSize
    $end = [Math]::Min($start + $ChunkSize, $registrations.Count)
    for ($registration = $start; $registration -lt $end; $registration++) {
        [void]$builder.AppendLine($registrations[$registration])
    }
    [void]$builder.AppendLine('}')
    [void]$builder.AppendLine()
}
[void]$builder.AppendLine('}  // namespace')
[void]$builder.AppendLine()
[void]$builder.AppendLine('void fm4_RegisterFunctions(rex::runtime::IModuleRegistrar* registrar) {')
for ($chunk = 0; $chunk -lt $chunkCount; $chunk++) {
    $name = "fm4_RegisterFunctionsChunk_{0:D3}" -f $chunk
    [void]$builder.AppendLine("  $name(registrar);")
}
[void]$builder.AppendLine('}')

$encoding = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($Path, $builder.ToString(), $encoding)

Write-Output "Split $($registrations.Count) registrations into $chunkCount noinline chunks ($ChunkSize maximum each)."
