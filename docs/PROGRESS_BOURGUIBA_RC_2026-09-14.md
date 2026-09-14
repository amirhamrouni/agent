# Hayat Tounes — Bourguiba RC verification

Version: `0.53.34`  
Version code: `87`  
Package: `com.amir.hayattounes`

## Engineering change

The Habib Bourguiba public-realm pass adds the road surface, sidewalks, lane markings and pedestrian crossings on top of the previously implemented curbs, median, drainage, benches, bollards, planters and street lamps.

A Godot 4.7.2 runtime failure exposed ambiguous type inference in `_build_crosswalks()`. The loop variables and calculated stripe coordinate were changed to explicit `float` types in commit `7d024d67229f2fb0f029a9d47fa4b1dec14035de`.

## Verified gates

GitHub Actions run `34877890020` completed successfully with:

- exact Godot `4.7.2.stable.official.ed1daf0bf`
- source reconstruction
- Android SDK/JDK setup
- Godot import and strict parser gate
- production main-scene runtime smoke
- Android debug export
- APK signature verification
- zipalign verification
- artifact upload

APK SHA-256:

`37f37ef13bb7b15f6d6a590677141f2740785079c0c3335bb12ebcaff5d83f24`

The reconstructed runtime/export source identity is pinned to:

- file count: `89`
- tree SHA-256: `637708f67ec6b099ddaaaf92b1b2d8ffb1fc2c3285a063b04cf4fe0d75d57060`
- verification run: `34878029068` — PASS

## Not verified / not claimed

The production runtime evidence still reports:

- `real_osm=false`
- `real_player_asset=false`
- `real_vehicle_count=0`
- `visual_milestone_pass=false`

Therefore visual realism is not claimed. Physical Android device acceptance is also still unverified, and this build is an RC/debug artifact rather than a final release.

## Next locked task

Install and exercise this exact APK on a physical Android device, record launch/gameplay/performance evidence, then continue the real-world asset and provenance work without weakening the existing runtime/source identity gates.
