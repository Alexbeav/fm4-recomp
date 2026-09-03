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

## Validated graphics profile

```toml
resolution_scale = 1
render_target_path_d3d12 = "rov"
readback_resolve = "full"
d3d12_readback_resolve_host_copy = true
```

Use the default guest vblank rate. The validated GPU and runtime were built
from the SDK fork at
[`2746217`](https://github.com/Alexbeav/rexglue-sdk/commit/2746217dfae26976c07a9bbba32108fc50f3e220).

## Known limitations

- Full resolve readback is required for visual correctness and causes large,
  hardware-dependent frame-rate drops.
- A fresh rebuild in the current Clang/libc++ development environment stops
  because the pinned SDK specializes `std::chrono::clock_time_conversion`,
  which that standard library does not provide. The last validated executable
  remains usable, but this SDK/toolchain mismatch must be resolved before
  binary packaging.
- The full campaign has not been completed. Sportsman is the current tested
  career boundary.
- A 2x internal resolution test produced stained-glass texture corruption.
- A 120 Hz guest-vblank override improved throughput but reintroduced screen
  flicker and player-car texture corruption.
- Automatic readback produced higher frame rates, but skipped resolves needed
  by FM4 and caused flickering, texture corruption, and heavy dips.
- Generated car thumbnails may preserve artifacts created by an older broken
  graphics profile until the game regenerates them.
- Online services and downloadable marketplace acquisition are outside the
  current test scope.

The graphics configuration is a validated combination, not a fully isolated
root-cause fix. Performance work must retain this profile as its correctness
reference.
