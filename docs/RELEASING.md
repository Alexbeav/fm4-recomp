# Builder-first release process

This file is the authority for FM4 release contents and review. The only
public release artifact currently authorized by the repository is a
deterministic source archive plus its SHA-256 checksum. Do not publish any
artifact until the project owner approves its exact contents and workflow.

## Public artifact boundary

The source archive is built from the exact paths in
[`release/source-files.txt`](../release/source-files.txt). The policy and
validated input identities are machine-readable in
[`release/release-policy.json`](../release/release-policy.json).

The archive must not contain:

- game files, disc images, XEX files, downloadable content, or Xbox system
  files;
- generated C++ translation under `fm4/generated`;
- FM4 executables, facade DLLs, SDK binaries, object files, or debug symbols;
- saves, user data, shader caches, logs, dumps, or captures; or
- local build and dependency directories.

`tools/Test-RepositoryBoundary.ps1` rejects tracked files outside the source
allowlist and rejects forbidden paths, extensions, sizes, and executable or
Xbox package magic. Ignored files are never package inputs.

## Create a review candidate

Use a clean reviewed commit for a final candidate:

```powershell
pwsh -File .\tools\Test-RepositoryBoundary.ps1
pwsh -File .\tools\New-SourceRelease.ps1 -Version 0.1.0-alpha.1
```

For an internal preview of uncommitted work, add `-AllowDirty`. The embedded
`SOURCE-PROVENANCE.json` then records that the worktree was dirty. A dirty
candidate is not publishable.

The packager writes a ZIP with sorted entries, no compression, and a fixed
entry timestamp. It also writes `<archive>.sha256`. Identical source bytes,
version, repository URL, and commit identity produce identical archives.

## Review gate

Before publication:

1. Run the boundary check from a clean checkout of the candidate commit.
2. Create the archive twice in separate output directories and compare its
   SHA-256 hashes.
3. Inspect every archive entry and `SOURCE-PROVENANCE.json` against the source
   allowlist.
4. Confirm `project_worktree_dirty` is `false`, and confirm the recorded FM4
   and SDK commits.
5. Test `tools/Build-Local.ps1 -ValidateOnly` with the validated game dump.
6. Complete a clean local build, startup smoke test, and the gameplay checks
   in [`STATUS.md`](STATUS.md).
7. Present the archive entry list, hashes, test evidence, and proposed release
   text to the project owner. Publication requires explicit approval.

## User-side build

The source archive does not contain an ISO extractor. The user extracts a
legally obtained copy of the game, then runs:

```powershell
pwsh -File .\tools\Build-Local.ps1 -GameDataRoot "D:\Games\FM4-extracted"
pwsh -File .\tools\Run-Local.ps1 -GameDataRoot "D:\Games\FM4-extracted"
```

The builder verifies the three required Xbox executable inputs by size and
SHA-256, clones the configured ReXGlue SDK commit with its submodules, builds
the SDK, copies the allowlisted source into `.local/work`, generates
translation there, and builds FM4 there. It writes `build-provenance.json`
beside the local executable. No game input or generated translation is
uploaded by these scripts, and the repository's retained development build is
not modified.

The run script passes `.local/user` explicitly as the user-data root. Release
testing therefore does not use or modify an existing profile in the user's
Documents folder.

The builder also asks the pinned ReXGlue CLI to generate its standard CMake
bootstrap file in a temporary local directory. This avoids treating an ignored
SDK-generated file from a developer checkout as release source.

The build requires Windows AMD64, Git, CMake 3.25 or newer, Ninja, and Clang.
LLVM 22 with the MSVC target is the validated compiler. The builder rejects a
MinGW/libc++ Clang target because its C++ ABI is incompatible with the
validated SDK and FM4 build. Downloads are limited to the pinned Git
repositories required to build the SDK.
