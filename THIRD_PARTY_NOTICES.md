# Third-party software notices

The FM4 source release does not contain third-party binaries or generated game
translation. It references and locally builds the following direct
dependency:

- [ReXGlue SDK](https://github.com/Alexbeav/rexglue-sdk), pinned by
  `release/release-policy.json`, is licensed under the BSD 3-Clause License.
  It includes or links additional components under their own terms and
  contains code derived from [Xenia](https://github.com/xenia-project/xenia),
  also under the BSD 3-Clause License.

The pinned SDK checkout is the authority for the complete dependency list and
the license texts applicable to a local build. Anyone who redistributes SDK
files or locally produced binaries must preserve the notices and satisfy the
licenses shipped with that exact SDK source. The FM4 source packager does not
package those files.

## Project artwork

The repository includes the user-supplied project image
`assets/fm4-recompiled-hero.png`. Names, logos, vehicle designs, and other
third-party visual elements in that image are not offered under the project's
GPL license. All such rights remain with their respective owners. The project
is not affiliated with or endorsed by Microsoft, Xbox, Turn 10 Studios,
Ferrari, or the Forza franchise.
