# License and content boundary

The independently authored source code, scripts, configuration, and
documentation in this repository are licensed under the GNU General Public
License, version 3 only (`GPL-3.0-only`), unless a file states otherwise. The
complete license text is in [`LICENSE`](../LICENSE).

That license grant is limited to material the project is entitled to license.
It does not grant rights to Forza Motorsport 4, Xbox software, game assets,
Xbox executable files, saves, disc images, downloadable content, trademarks,
or other third-party material. Users must provide their own legally obtained,
extracted game data.

The user-supplied hero artwork in `assets/fm4-recompiled-hero.png` contains
third-party names, marks, and visual elements. Those elements are not covered
by the project's GPL license grant. They remain the property of their
respective owners and are shown only to identify the project. Their inclusion
does not imply affiliation with or endorsement by Microsoft, Xbox, Turn 10
Studios, Ferrari, or any other rights holder.

## Generated translation

ReXGlue generates C++ from user-supplied Xbox executables. Generated
translation is created only on the user's computer, under `fm4/generated`,
and is excluded from source archives and version control. This project makes
no license grant for that generated output.

Public releases use the builder-first process in
[`RELEASING.md`](RELEASING.md). They do not include a precompiled FM4
executable or recompiled facade DLLs. Shipping a linked binary would require a
separate rights and GPL compliance review; the release scripts do not provide
that path.

## Dependencies

The local builder obtains the pinned ReXGlue SDK source and builds it on the
user's computer. ReXGlue and its dependencies keep their own licenses and
notices. See [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

This document records the project's release policy. It is not legal advice.
