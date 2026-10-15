# Release notes

## Source kit and GitHub automation

This experimental source kit requires a local build before you can play.
Download the named source ZIP asset and extract it into a local folder.
Follow the [setup and build instructions](../README.md#download-and-start-here).

The kit requires Windows x64, PowerShell 7, the documented compiler tools,
and your own extracted Europe Game of the Year copy of Forza Motorsport 4.
It contains no game data, generated translation, SDK binaries, or playable executable.
The license is `GPL-3.0-only` within the [content boundary](LEGAL.md).

GitHub now checks source packaging on pushes and pull requests.
Maintainers can prepare a draft with the tested archive and SHA-256 checksum.
The release allowlist now includes the project and acceptance manifests.
These changes do not change game code or the validated SDK pin.

## Tested behavior and limits

Gameplay evidence remains the Windows AMD64 validation from 2026-09-03.
Campaign progression is known good through Amateur and Clubman into Sportsman.
Later campaign progression is unvalidated.
The four Disc 2 packages can be installed from your own extracted media.
Online services and marketplace acquisition are outside the tested scope.

Fresh profiles can cache blank car thumbnails.
The conservative graphics configuration can stutter and run at about 30 FPS.
Higher resolution and timing overrides caused visual corruption in earlier tests.
See [current status](STATUS.md) for the full tested boundary.

Source CI checks packaging only. A new local build and gameplay review remain
required before publication of a new release.

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
