# Hayat Tounes — Physical Android Acceptance Hardening

Date: 2026-09-14
Game version: 0.53.35
Version code: 88

## Locked production task

Physical Android acceptance remains the next locked production gate. This update hardens that gate without changing gameplay/runtime source or incrementing the game version.

## Engineering changes

- Upgraded `tools/android/device_acceptance.py` evidence schema to version 2.
- `--expected-sha256` is now mandatory.
- Added installed package identity validation from `dumpsys package`:
  - expected `versionName`
  - expected `versionCode`
- Added fail-closed physical-device enforcement.
- Android emulator markers and `ro.kernel.qemu=1` are rejected for production physical acceptance.
- Added a test-only `--allow-emulator` escape hatch; it must not be used for production evidence.
- Added `package-dump.txt` and `thermalservice.txt` to the evidence bundle.
- Preserved existing install, process-alive, screenshot, framestats, logcat fatal scan, and meminfo gates.

## Verification

GitHub Actions workflow: `Android Device Acceptance Harness`

Run: `34898618333`
Result: `SUCCESS`
Commit tested: `48ab906cb070ae139a1eb02db9137ec069b272d3`

The contract test covers:

1. PASS on a non-emulated fixture with exact APK SHA and exact installed version.
2. FAIL on APK SHA mismatch.
3. FAIL on emulator evidence when physical acceptance is required.

## Locked acceptance identity

APK SHA-256:

`3224a88763998c85d21a823625828477ce9f01b5eb3b3ccd8b058f8b809e7a3d`

Expected installed package:

- package: `com.amir.hayattounes`
- versionName: `0.53.35`
- versionCode: `88`

Required evidence after real-device execution:

- `device-acceptance.json`
- `launch.png`
- `logcat.txt`
- `gfxinfo-framestats.txt`
- `meminfo.txt`
- `package-dump.txt`
- `thermalservice.txt`

## Claims intentionally not made

- Physical Android acceptance: NOT VERIFIED
- Visual realism milestone: NOT VERIFIED / NOT CLAIMED
- Final release: NOT VERIFIED / NOT CLAIMED

The existing verified Android RC remains the playable candidate until the exact APK passes this gate on a real device.
