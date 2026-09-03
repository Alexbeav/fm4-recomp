# Current status

Last validated: 2026-09-03 on Windows AMD64 with D3D12.

## Working

| Area | Validated result |
|---|---|
| Startup | The title reaches the main menu and loads the tested profile. |
| Career | The mandatory opening race completes. Saving, achievements, and driver-level progression work. The tested save progressed through Amateur and Clubman into Sportsman. |
| Modules | `XMediaFacade_default.xex` and `SpeechFacade_default.xex` load as recompiled modules. |
| Disc 2 | The four FM4 marketplace packages install into user data. Installed cars appear in the browser and the menu no longer offers Disc 2 installation. |
| Graphics | The validated native-resolution profile renders the tested player-car shadow, car materials, road lighting, and trackside assets correctly. |
| Local release build | The builder-first path validates the three XEX inputs, builds SDK commit `f16992c`, generates all three modules in isolated local state, and completes all 293 FM4 build steps. The resulting executable passed startup smoke tests and an operator launch through first-profile setup and car selection. |

## Validated graphics profile

```toml
resolution_scale = 1
render_target_path_d3d12 = "rov"
readback_resolve = "full"
d3d12_readback_resolve_host_copy = true
```

Use the default guest vblank rate. The validated GPU and runtime were built
from the SDK fork at
[`f16992c`](https://github.com/Alexbeav/rexglue-sdk/commit/f16992c92e610c2d71773994436b442d9946f4e1).

## Known issues

- Car-thumbnail generation is under investigation. A fresh isolated profile
  generated a highly compressible blank thumbnail: the showroom background
  rendered, but the car was missing. Blank results can persist in the
  profile's thumbnail cache.
- Full resolve readback is required for the current visual-correctness
  baseline and has substantial, hardware-dependent synchronization cost. The
  validated local build exhibited stutter and about 30 FPS while the host GPU
  was only partly utilized. Performance and remaining visual issues are still
  being improved.

## Build and validation boundaries

- Fresh Windows builds require one consistent C++ ABI. The SDK and FM4 now
  build successfully with LLVM 22 targeting the MSVC ABI after adding a
  feature-gated fallback for standard libraries that do not provide C++20
  `clock_time_conversion` and `clock_cast`. Do not mix an MSVC-ABI SDK with a
  MinGW/libc++ FM4 build; C++ runtime symbols will not link across that boundary.
- Campaign progression is known good through Amateur and Clubman and into the
  Sportsman tier. The campaign beyond Sportsman has not been validated.
- A 2x internal resolution test produced stained-glass texture corruption.
- A 120 Hz guest-vblank override improved throughput but reintroduced screen
  flicker and player-car texture corruption.
- Automatic readback produced higher frame rates, but skipped resolves needed
  by FM4 and caused flickering, texture corruption, and heavy dips.
- Online services and downloadable marketplace acquisition are outside the
  current test scope.
- The `v0.1.0-alpha.1` release is source-only. Users must supply the three
  validated executable inputs from their own legally obtained game copy and
  build locally; no game data, generated translation, or compiled executable
  is distributed.

The graphics configuration is a validated combination, not a fully isolated
root-cause fix. Performance work must retain this profile as its correctness
reference.
