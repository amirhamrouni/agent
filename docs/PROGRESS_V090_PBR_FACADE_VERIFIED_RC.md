# Hayat Tounes 0.53.35 — V090 PBR façade verified RC

## Verified source

- Runtime source commit: `a33d9b6687358758235ddb3e8dad075915e5139d`
- Runtime identity run: `34897209313`
- Identity evidence artifact: `10369281907`
- Runtime/export files: `95`
- Runtime tree SHA-256: `925fd6d6fe7a57a3a60f9740e9028dc911e4f85a96f2bd74c3dbf5694e670fab`

The identity manifest explicitly includes:

- `scripts/world/art/TunisFacadePass.gd`
- `scripts/world/art/TunisMaterialLibrary.gd`
- `shaders/tunis_asphalt.gdshader`
- `shaders/tunis_plaster.gdshader`

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

Android artifact ID: `10369690267`

Android artifact ZIP SHA-256:

`85760e7b3a684e3e6e0dcf533a6f34fc5903167749aaeac284c3c11d969bac29`

## Verified project artifact

Workflow run `34897917014` reconstructed the project and required the same `95`-file runtime identity before packaging.

- Source artifact gate: PASS
- Project artifact ID: `10369154541`
- Project TAR SHA-256: `0665b5447d6d1774d26ceb79977737d67d90bcab79db3e0dc0e977a2368c8a68`
- Project artifact ZIP SHA-256: `cc2099e1362b93ec93ef938c33dc39e56fb0f81dce4cad86162455cf2a058349`

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
