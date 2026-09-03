# Forza Motorsport 4 Recompiled

An experimental static recompilation of the Xbox 360 version of Forza
Motorsport 4 using [ReXGlue](https://github.com/rexglue/rexglue-sdk).

This repository contains project source, recompilation metadata, and build
configuration. It does not contain game data, Xbox system files, saves, or
compiled executables. You must provide files from your own copy of the game.

The project is licensed under `GPL-3.0-only`. The license applies only to
material this project is entitled to license; it does not grant rights to game
files or locally generated translation. See [License and content
boundary](docs/LEGAL.md).

## Project status

This is a development snapshot, not a packaged release. On the tested Windows
AMD64 system, the current tree can:

- boot into the game and load an existing profile;
- complete races and save career progress;
- progress from Amateur through Clubman and into Sportsman;
- load the two facade modules used by the game;
- install all four content packages from an extracted Disc 2; and
- render the tested races without the rectangular player shadow, corrupt car
  materials, or oscillating road brightness.

The validated graphics profile is intentionally conservative. It uses native
resolution, the D3D12 ROV path, full resolve readback, synchronous host-copy
completion, and the default guest vblank rate. Full readback is expensive, so
performance is not yet release quality. Higher internal resolution and timing
overrides are also not considered safe.

See [Current status](docs/STATUS.md) for the tested boundary and known issues.

## Requirements

- Windows AMD64
- Git, CMake 3.25 or newer, Ninja, and Clang
- a legally obtained, extracted Forza Motorsport 4 game tree

The current graphics baseline uses the project SDK fork at commit
[`2746217`](https://github.com/Alexbeav/rexglue-sdk/commit/2746217dfae26976c07a9bbba32108fc50f3e220).
That fork contains work which has not all been accepted upstream. The local
builder obtains and builds the exact pinned source automatically.

The project expects these game executables:

```text
extracted/default.xex
extracted/XMediaFacade_default.xex
extracted/SpeechFacade_default.xex
```

## Local build

The supported release path verifies the required Xbox executables, builds the
pinned SDK, generates translation on your computer, and builds FM4:

```powershell
pwsh -File .\tools\Build-Local.ps1 -GameDataRoot "D:\Games\FM4-extracted"
pwsh -File .\tools\Run-Local.ps1 -GameDataRoot "D:\Games\FM4-extracted"
```

Use `-ValidateOnly` on the build command to check the dump and toolchain
without downloading or building the SDK. Local dependencies, generated code,
and build outputs stay under `.local`; the retained development build is not
modified. The run script also isolates profiles, saves, and caches under
`.local/user`.

## Developer build

From the repository root:

```powershell
Push-Location .\fm4
..\sdk\win-amd64\bin\rexglue.exe codegen .\fm4_manifest.toml
cmake --preset win-amd64-release
cmake --build --preset win-amd64-release --parallel 2
Pop-Location
```

The generated FM4 registrar is unusually large. The build automatically
splits it into bounded helper functions so Clang can compile it reliably. Read
[Build notes](BUILD-NOTES.md) before changing function boundaries or the
generation pipeline.

Run a completed local build with:

```powershell
.\Launch FM4.bat
```

## Disc 2 content

Extract the four marketplace-content packages from your own Disc 2 into one
directory, then run:

```powershell
.\Launch FM4 Disc 2 Install.bat "D:\path\to\disc2-packages"
```

The installer validates each STFS package's title ID and content type before
passing it to ReXGlue's content manager. Existing packages are skipped. After
installation, normal launches use the copy in user data and no longer require
the source directory.

## Development notes

- [Current status and limitations](docs/STATUS.md)
- [Reusable findings and upstream candidates](docs/CONTRIBUTIONS.md)
- [Canonical documentation sources](docs/canonical-sources.md)

## Repository policy

Do not commit extracted game files, generated source, user data, saves,
diagnostic captures, installed SDK files, or compiled binaries. Inspect every
staged change before publishing it.

Public artifacts follow the [builder-first release process](docs/RELEASING.md):
source and checksums only. The repository does not authorize publishing a
precompiled FM4 executable or generated translation.

This project is not affiliated with or endorsed by Microsoft, Xbox, Turn 10
Studios, or the Forza franchise.
