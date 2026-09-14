# Hayat Tounes 0.53.35 / versionCode 88

## Scope

This increment hardens the Android production candidate without claiming visual completion.

## Changes

- Added `source_overlay/assets/branding/hayat_tounes_icon.svg`.
- Bound `application/config/icon` to the project icon.
- Bound Android launcher icon fields to the same source asset.
- Incremented version name from `0.53.34` to `0.53.35` and Android version code from `87` to `88`.
- Updated Android RC paths and artifact names for `0.53.35`.
- Android RC now fails closed if Godot emits `No project icon specified`.
- Runtime smoke now requires `real_osm=true` in diagnostics.
- Bourguiba runtime gate explicitly requires OSM runtime and navigation PASS markers.
- Android SDK bootstrap was hardened to request `platform-tools` explicitly before installing the exact pinned dependencies.

## Verified runtime source identity

Workflow run `34896777244` passed with:

- Runtime/export file count: `95`
- Tree SHA-256: `31ab8f4ee16643a3842d70af39863a4079f00325048b42418a0bbefa81f0d006`
- Algorithm: `sha256-path-digest-size-v1`

## Verified Android RC

Workflow run `34896744422` completed successfully using Godot `4.7.2.stable.official.ed1daf0bf`.

Verified gates:

- Reconstruction: PASS (`57` base files, `21` overlay-pack files, `27` loose overlay files, `76` GDScript files)
- Parser/import: PASS
- Bourguiba reference gate: PASS
- Bourguiba environment gate: PASS (`728` generated environment elements)
- Bounded OSM runtime gate: PASS (`146` buildings, `191` roads, `1216` generated OSM children)
- Navigation gate: PASS (`827` nodes, `924` edges, largest component `741`, ratio `0.896`, span `3253.0 m`)
- Bourguiba blockout gate: PASS (`434` generated, `12` required nodes)
- Production runtime smoke: PASS with `real_osm=true`
- Project/launcher icon import and Android export: PASS
- APK Signature Scheme v2: PASS
- APK Signature Scheme v3: PASS
- zipalign: PASS

APK SHA-256:

`2b1e75c58debcd8a049a0b127a13965a64fb4685e4c4fc412432f00f7d9702ef`

GitHub artifact ID: `10368562504`

Artifact ZIP SHA-256:

`0c3fd34ddf7fbf928e50ca657c6f7ef76eedc73fb893d218370d8a5fe5be2d7a`

## Remaining locked acceptance task

Physical Android execution is still unverified. The exact APK above must pass the existing device acceptance harness and produce:

- `device-acceptance.json`
- `launch.png`
- `logcat.txt`
- `gfxinfo-framestats.txt`
- `meminfo.txt`

## Explicit non-claims

- No visual realism claim: `real_player_asset=false`, `real_vehicle_count=0`, `visual_milestone_pass=false`.
- No final release claim.
- No physical Android acceptance claim until device evidence exists.
