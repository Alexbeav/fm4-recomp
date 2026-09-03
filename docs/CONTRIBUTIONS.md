# Reusable findings and upstream candidates

This document separates FM4-specific project data from general ReXGlue work.
It records what is supported by source changes and playtesting; it does not
claim that every candidate is ready to merge upstream.

## FM4 corpus additions

The following data is useful to a shared Xbox 360 recompilation corpus:

- Title ID `4D530910` and the main, XMediaFacade, and SpeechFacade executable
  layout.
- The current function tables, including the standalone virtual-call thunks,
  adapter thunks, and vtable leaf functions needed at the tested career tier
  boundaries.
- Dynamic-module guest paths and the requirement to unregister their mappings
  and reset module heaps when an XEX unloads.
- Disc 2 package identities `4d53091000000001` through
  `4d53091000000004`, their marketplace-content type, and the validated STFS
  installation layout.
- The observed `XAM` message `0x2B003` and writable cache-device behavior
  required by this title.
- A graphics workload where a 512 x 512, 2x-MSAA `k_16_16` render target is
  resolved as signed integer data with exponent bias and then sampled by scene
  material shaders.
- The validated FM4 correctness profile and negative results for automatic
  readback, 2x internal scaling, and vblank overrides.

The corpus should store metadata, hashes, addresses, traces, and test outcomes.
It must not store game executables, extracted assets, user profiles, or Disc 2
packages.

## Good upstream candidates

These changes are general enough to propose to ReXGlue as focused pull
requests with tests:

1. Correct Xenon `vmsum` reduction and overflow semantics.
2. Treat empty resolve rectangles as successful no-ops.
3. Unregister recompiled module mappings and reset module heaps on XEX unload.
4. Mount writable guest cache devices.
5. Handle XAM message `0x2B003`.
6. Resume-entry and parent-owned continuation handling for indirect dispatch.
7. Stable address-based generated-code shards and bounded initial function
   registration.
8. Guest exception reporting across fiber boundaries.
9. Lightweight guest frame statistics, high-resolution Windows sleeps, and an
   optional guest-vblank override.
10. Render-target lifecycle tracing as an opt-in diagnostic facility.

## Upstream work that needs separation or more proof

- Direct guest-RAM resolve readback is essential to the validated FM4 profile,
  but its synchronization and performance behavior need focused tests before
  upstream submission.
- Signed-integer resolve packing and texture-fetch scaling are independently
  valid format-handling improvements. They did not, by themselves, remove the
  FM4 rectangular shadow, so they should not be presented as that fix.
- Automatic and size-gated readback improve speed but are incorrect for FM4's
  observed workload. The heuristic needs dependency tracking or a title-safe
  fallback before it can replace full readback.
- The broader continuation and function-boundary series should be split into
  reviewable patches with unit tests and without project-specific diagnostics.
- FM4's Disc 2 discovery policy belongs in this project. Only the generic STFS
  validation and content-manager behavior should be considered for the SDK.
