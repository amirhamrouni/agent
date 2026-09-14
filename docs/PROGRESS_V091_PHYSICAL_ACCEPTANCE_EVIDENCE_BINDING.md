# Hayat Tounes V091 — Physical Android Acceptance Evidence Binding

## Scope

This pass stays inside the locked physical-device acceptance task. It does not change gameplay/runtime source and therefore does not increment `versionName` or `versionCode`.

Preserved release candidate:

- versionName: `0.53.35`
- versionCode: `88`
- required APK SHA-256: `3224a88763998c85d21a823625828477ce9f01b5eb3b3ccd8b058f8b809e7a3d`

## Engineering changes

- Upgraded `device-acceptance.json` from schema 2 to schema 3.
- Removed raw Android serial storage. Only `device_serial_sha256` is persisted.
- Removed raw build fingerprint storage. Only `build_fingerprint_sha256` is persisted.
- Added SHA-256 and byte-size metadata for each required evidence file.
- Added `acceptance_binding_sha256` over package id, exact APK hash, installed versionName, installed versionCode and hashed device serial.
- Added `tools/android/verify_device_acceptance.py` as an independent fail-closed verifier.
- Added contract coverage that mutates `logcat.txt` after capture and requires verification failure.
- Emulator rejection remains enforced for production acceptance.

## Verification

Local contract:

- Python compile: PASS
- fake physical-device harness: PASS
- evidence verifier: PASS
- tamper rejection: PASS
- wrong APK hash rejection: PASS
- emulator rejection: PASS

GitHub Actions:

- workflow: `Android Device Acceptance Harness`
- run: `34902044044`
- result: `SUCCESS`

## Production status

Still NOT VERIFIED:

- execution on a real Android handset
- device performance acceptance
- visual milestone
- final release

No realism claim is made by this pass.

## Next locked task

Run the exact APK on a real non-emulated Android device, collect all seven evidence files, then run:

```bash
python3 tools/android/verify_device_acceptance.py device-acceptance-evidence \
  --expected-apk-sha256 3224a88763998c85d21a823625828477ce9f01b5eb3b3ccd8b058f8b809e7a3d \
  --expected-version-name 0.53.35 \
  --expected-version-code 88
```

Only verifier PASS can satisfy the physical-device evidence gate.
