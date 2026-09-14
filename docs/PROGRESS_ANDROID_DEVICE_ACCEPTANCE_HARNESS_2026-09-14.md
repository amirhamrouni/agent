# Hayat Tounes — Android Device Acceptance Harness

Date: 2026-09-14
Version: 0.53.34
Version code: 87
Package: `com.amir.hayattounes`

## Verified RC baseline

Latest Android RC workflow run: `34879709859`
Source commit: `658700c6e1fb0cba295bec7289f47793aa8f8c01`
Godot: `4.7.2.stable.official.ed1daf0bf`

Verified gates:
- source reconstruction: PASS
- Godot parser/import: PASS
- deterministic Bourguiba blockout runtime gate: PASS
- generated Bourguiba geometry: 434 nodes/items
- required Bourguiba blockout roots: 12
- production runtime smoke: PASS
- Android debug export: PASS
- APK signature v2/v3: PASS
- zipalign: PASS

Latest verified APK:
- size: `28,564,788` bytes
- SHA-256: `398c34f3e2d26294b01beaa29e9192727c712c1fbf11e1e28e14ac78db2c5add`

## Physical-device acceptance harness

Implemented: `tools/android/device_acceptance.py`
Contract test: `tools/tests/test_device_acceptance_harness.py`
CI workflow: `.github/workflows/android-device-acceptance-harness.yml`
Harness CI run: `34883776560` — PASS.

The harness is fail-closed and requires all of the following before emitting `ANDROID_DEVICE_ACCEPTANCE_PASS`:
1. APK exists and optional expected SHA-256 matches.
2. Exactly one online Android device is resolved, unless a serial is provided.
3. APK installs successfully through ADB.
4. `com.amir.hayattounes` is present after installation.
5. Launcher command succeeds.
6. App process remains alive after the settle period.
7. Screenshot capture succeeds.
8. `dumpsys gfxinfo ... framestats` returns evidence.
9. Runtime logcat has no matched fatal/ANR/Godot script error markers.
10. Memory evidence is collected.

Required physical-device evidence output:
- `device-acceptance.json`
- `launch.png`
- `logcat.txt`
- `gfxinfo-framestats.txt`
- `meminfo.txt`

Example execution:

```bash
python3 tools/android/device_acceptance.py \
  --apk Hayat-Tounes-v0.53.34-Bourguiba-blockout-verified.apk \
  --expected-sha256 398c34f3e2d26294b01beaa29e9192727c712c1fbf11e1e28e14ac78db2c5add \
  --output-dir device-acceptance-evidence
```

## Current release boundary

Physical Android acceptance remains **NOT VERIFIED** because no physical device was available to this CI/runtime environment. The new harness verifies the acceptance procedure itself; it does not substitute for executing it on a real phone.

Visual realism remains **NOT CLAIMED**. Current readiness flags remain:
- `real_osm=false`
- `real_player_asset=false`
- `real_vehicle_count=0`
- `visual_milestone_pass=false`

Next locked task: execute the verified APK on a physical Android device with this harness, preserve evidence, then proceed to real-world asset/provenance integration.
