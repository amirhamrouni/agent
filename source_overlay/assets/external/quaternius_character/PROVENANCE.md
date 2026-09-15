# Tounsi 3ayach — Player Character Provenance

Asset: `character.glb`

Upstream repository: `programasweights/avatar`

Pinned upstream commit: `ddd5fc34a445bcded3cf9836607aaeebc19a5c78`

Upstream path: `public/assets/character.glb`

Git blob SHA-1: `b3fd79533fdb9fcedd077744f7e120920eb6cc97`

Original character author: Quaternius

Original pack: Universal Base Characters — Standard / Superhero Male FullBody

License: CC0 1.0 Universal / public domain dedication. The upstream repository documents this character as CC0 and preserves its Quaternius license separately from the repository's MIT code license.

Purpose in this project: replace the emergency primitive `FallbackPlayerVisual` in Android production builds with a real rigged humanoid asset. The build pipeline downloads the exact pinned upstream object, verifies its Git blob hash, and bundles it into the Godot project before import/export. No runtime network fetch is used.
