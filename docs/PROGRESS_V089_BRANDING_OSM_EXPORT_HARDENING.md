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
- Bourguiba runtime gate now explicitly requires OSM runtime and navigation PASS markers.

## Last verified baseline

Android RC run `34892519767` on commit `b9f24ca9d0f6ad67bffb4b8c6e815d857d7c1824` passed parser/import, Bourguiba reference/environment/OSM/navigation/blockout gates, production runtime smoke, Android export, signature verification and zipalign.

Verified OSM runtime evidence from that run:

- 146 buildings
- 191 roads
- 827 graph nodes
- 924 graph edges
- `real_osm=true`

## Current candidate

The `0.53.35` candidate must not replace the verified baseline until its new GitHub Actions runs pass. Physical Android execution remains unverified.

## Explicit non-claims

- No visual realism claim.
- No final release claim.
- No physical Android acceptance claim until device evidence exists.
