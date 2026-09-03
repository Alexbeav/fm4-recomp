# Release notes

## v0.1.0-alpha.1

This first experimental source release provides a builder-first path for
Forza Motorsport 4. It validates the user's three Xbox executable inputs,
builds the pinned ReXGlue SDK, generates the three recompiled modules locally,
and builds and launches FM4 in isolated local state.

Campaign progression is known good through Amateur and Clubman and into the
Sportsman tier. Later campaign progression has not been validated.

### Known issues

- Car-thumbnail generation is under investigation. Fresh profiles can produce
  a blank thumbnail where the showroom background appears without the car, and
  the blank result can remain cached.
- Performance and visuals need further improvement. The current
  correctness-oriented full-readback profile can stutter and run at about
  30 FPS despite low host-GPU utilization. Faster experimental configurations
  have caused visual corruption and are not release defaults.

Online services and downloadable marketplace acquisition are outside the
tested scope. Installation of the four Disc 2 content packages is supported
from the user's own extracted game media.

This release contains project source and build tooling only. It does not
contain game files, generated translation, saves, SDK binaries, or a compiled
FM4 executable. The project is licensed under `GPL-3.0-only`; users must supply
the validated inputs from their own legally obtained copy of the game.
