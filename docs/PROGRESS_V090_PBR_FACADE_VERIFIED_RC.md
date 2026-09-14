# Hayat Tounes 0.53.35 — V090 PBR façade verified RC

## Verified source

- Runtime source commit: `a33d9b6687358758235ddb3e8dad075915e5139d`
- Runtime identity run: `34897209313`
- Runtime/export files: `97`
- Runtime tree SHA-256: `925fd613e8a1a75b1f7f22ed811e7aa112912843ed732c1e14dac1daf194187b`

## Engineering delta

The current source includes the verified façade material pass and two dedicated Godot shaders:

- `scripts/world/art/TunisFacadePass.gd`
- `scripts/world/art/TunisMaterialLibrary.gd`
- `shaders/tunis_asphalt.gdshader`
- `shaders/tunis_plaster.gdshader`

This is a material/geometry quality increment. It is not evidence of visual realism.

## Android RC evidence

Workflow run `34897145165` completed successfully using Godot `4.7.2.stable.official.ed1daf0bf`.

- Reconstruction: PASS (`57` base, `21` overlay-pack, `28` loose overlay, `76` GDScript)
- Parser/import: PASS
- Bourguiba reference gate: PASS
- Environment gate: PASS (`16` façades, `52` shopfronts, `52` signs, `28` balconies, `780` generated environment elements)
- OSM runtime gate: PASS (`146` buildings, `191` roads, `1216` runtime children)
- Navigation gate: PASS (`827` nodes, `924` edges, largest component `741`, ratio `0.896`, span `3253 m`)
- Blockout gate: PASS (`434` generated, `12` required nodes)
- Production runtime smoke: PASS with `real_osm=true`
- Project/launcher icon import: PASS
- Android export: PASS
- APK signature v2/v3: PASS
- zipalign: PASS

APK SHA-256:

`3224a88763998c85d21a823625828477ce9f01b5eb3b3ccd8b058f8b809e7a3d`

Artifact ID: `10369690267`

Artifact ZIP SHA-256:

`85760e7b3a684e3e6e0dcf533a6f34fc5903167749aaeac284c3c11d969bac29`

## Locked next acceptance

The exact APK above still requires physical Android device acceptance. Required evidence remains:

- `device-acceptance.json`
- `launch.png`
- `logcat.txt`
- `gfxinfo-framestats.txt`
- `meminfo.txt`

## Non-claims

- Physical Android acceptance: NOT VERIFIED
- Real player asset: false
- Real vehicle count: 0
- Visual milestone: false
- Visual realism: NOT CLAIMED
- Final release: NOT CLAIMED
