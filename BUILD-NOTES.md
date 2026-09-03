# FM4 build notes

## Pinned Windows toolchain

Build the SDK and FM4 with the same C++ ABI. The validated packaging build uses
LLVM 22's MSVC target (`C:\Program Files\LLVM\bin\clang++.exe`) for both. The
Retcomm compiler targets MinGW/libc++; it must not consume an SDK built for the
MSVC ABI because exported C++ symbols have different names and standard-library
types.

The pinned SDK needs a feature-gated compatibility definition of
`std::chrono::clock_time_conversion` and `std::chrono::clock_cast` when
`__cpp_lib_chrono` is older than C++20. Its libmspack build must also use the
canonical `libmspack/libmspack/mspack` source directory. The cabextract path is
a symbolic-link mirror that may be checked out as one-line text files on
Windows. These fixes are recorded in SDK commit
[`f16992c`](https://github.com/Alexbeav/rexglue-sdk/commit/f16992c92e610c2d71773994436b442d9946f4e1).

The builder-first release path installs the SDK under `.local\sdk-install` and
builds FM4 under:

```text
.local\work\fm4\out\build\win-amd64-release
```

It asks the SDK CLI to generate its standard CMake bootstrap locally, copies
only allowlisted project source into `.local\work`, and generates all
game-derived translation there.
The 2026-09-03 end-to-end test completed the 293-target FM4 build and a bounded
15-second startup smoke test. The original known-good executable retained SHA-256
`4339E81F9CE190099F8756616CEC2C8AA6BB105E33B38E577A103196D2311281`.

## Generated function registrar

FM4 generates approximately 292,000 function registrations in one C++ source
file. Clang 22 exhausts memory when it optimizes the original single function.
Compiling the original function at `-O0` can leave late registrations unusable
at runtime.

The CMake build runs the splitter automatically when code generation changes
the registrar. To apply it manually for inspection, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Split FM4 Registrar.ps1"
```

The idempotent script rewrites `fm4/generated/default/fm4_register.cpp` into
bounded, non-inlined helper functions. `fm4/CMakeLists.txt` compiles this
generated file and the startup-only `fm4_init.cpp` dispatcher at `-O0`. The
dispatcher otherwise exhausts memory during an optimized compile on a busy
development host. Recompiled game-code translation units keep the release
optimization settings.

SDK configurations that precompile the generated `fm4_pch.h` must exclude the
two `-O0` startup sources. Clang rejects a PCH built at the release optimization
level when the consuming translation unit uses `-O0`.

Before testing a rebuilt executable, verify that the script reports the same
registration count before and after splitting.

The main executable dispatch table is populated from `PPCFuncMappings` in
`fm4/generated/default/fm4_init.cpp`. A targeted manual rebuild after adding a
function must compile that file, `fm4_register.cpp`, and every affected
`fm4_recomp.*.cpp` segment before relinking. `fm4_register.cpp` alone does not
update the main-image dispatch table.

When the manifest's dynamic-module set changes, also rebuild
`generated/default/module_registry.cpp`. Relinking with a stale registry can
silently omit a facade DLL and fail only when the game first loads that module.
