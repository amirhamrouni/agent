#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HARNESS = ROOT / "tools/android/device_acceptance.py"


def write_fake_adb(path: Path, *, emulator: bool = False) -> None:
    qemu = "1" if emulator else "0"
    model = "sdk_gphone64_arm64" if emulator else "FixturePhone"
    fingerprint = "generic/sdk_gphone/emulator" if emulator else "fixture/vendor/device:16/test/release-keys"
    path.write_text(
        f"""#!/usr/bin/env python3
import sys
args=sys.argv[1:]
if args==['version']:
 print('Android Debug Bridge version 1.0.41'); raise SystemExit(0)
if args==['devices']:
 print('List of devices attached\\nFAKE123\\tdevice'); raise SystemExit(0)
if args[:2]==['-s','FAKE123']:
 args=args[2:]
if args[:2]==['install','-r']:
 print('Success'); raise SystemExit(0)
if args[:2]==['shell','getprop']:
 props={{
  'ro.product.manufacturer':'FixtureVendor',
  'ro.product.model':'{model}',
  'ro.product.name':'fixture_product',
  'ro.product.device':'fixture_device',
  'ro.hardware':'fixture_hw',
  'ro.build.version.release':'16',
  'ro.build.version.sdk':'36',
  'ro.product.cpu.abi':'arm64-v8a',
  'ro.build.fingerprint':'{fingerprint}',
  'ro.kernel.qemu':'{qemu}',
 }}
 print(props.get(args[2],'')); raise SystemExit(0)
if args[:3]==['shell','pm','path']:
 print('package:/data/app/com.amir.hayattounes/base.apk'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','package']:
 print('Packages:\\n  Package [com.amir.hayattounes]\\n    versionCode=88 minSdk=24 targetSdk=35\\n    versionName=0.53.35'); raise SystemExit(0)
if args[:2]==['logcat','-c']:
 raise SystemExit(0)
if args[:3]==['shell','am','force-stop']:
 raise SystemExit(0)
if args[:2]==['shell','monkey']:
 print('Events injected: 1'); raise SystemExit(0)
if args[:2]==['shell','pidof']:
 print('4242'); raise SystemExit(0)
if args[:2]==['exec-out','screencap']:
 sys.stdout.buffer.write(b'\\x89PNG\\r\\n\\x1a\\nfixture'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','gfxinfo']:
 print('---PROFILEDATA---\\nFlags,IntendedVsync,Vsync'); raise SystemExit(0)
if args[:2]==['logcat','-d']:
 print('Godot Engine started successfully'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','meminfo']:
 print('TOTAL PSS: 12345'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','thermalservice']:
 print('Thermal Status: 0'); raise SystemExit(0)
print('UNHANDLED', args, file=sys.stderr); raise SystemExit(2)
""",
        encoding="utf-8",
    )
    path.chmod(0o755)


def invoke(work: Path, apk: Path, digest: str, env: dict[str, str], *extra: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [
            sys.executable, str(HARNESS),
            "--apk", str(apk),
            "--expected-sha256", digest,
            "--expected-version-name", "0.53.35",
            "--expected-version-code", "88",
            "--output-dir", str(work / "evidence"),
            "--settle-seconds", "1",
            *extra,
        ],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
    )


def main() -> int:
    with tempfile.TemporaryDirectory() as td:
        work = Path(td)
        bin_dir = work / "bin"
        bin_dir.mkdir()
        apk = work / "test.apk"
        apk.write_bytes(b"hayat-tounes-device-acceptance-fixture")
        digest = hashlib.sha256(apk.read_bytes()).hexdigest()

        fake_adb = bin_dir / "adb"
        write_fake_adb(fake_adb)
        env = os.environ.copy()
        env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")

        proc = invoke(work, apk, digest, env)
        if proc.returncode != 0:
            print(proc.stdout)
            print(proc.stderr, file=sys.stderr)
            return proc.returncode
        if "ANDROID_DEVICE_ACCEPTANCE_PASS" not in proc.stdout:
            raise SystemExit("missing PASS marker")
        result = json.loads((work / "evidence/device-acceptance.json").read_text(encoding="utf-8"))
        assert result["schema_version"] == 2
        assert result["status"] == "PASS"
        assert result["apk_sha256"] == digest
        assert result["device_serial"] == "FAKE123"
        assert result["checks"]["physical_device"] == "PASS"
        assert result["checks"]["installed_version"] == "PASS"
        assert result["installed_package"] == {"version_name": "0.53.35", "version_code": 88}
        for name in ("launch.png", "logcat.txt", "gfxinfo-framestats.txt", "meminfo.txt", "package-dump.txt", "thermalservice.txt"):
            assert (work / "evidence" / name).is_file(), name

        bad_dir = work / "bad"
        bad = subprocess.run(
            [sys.executable, str(HARNESS), "--apk", str(apk), "--expected-sha256", "0" * 64,
             "--output-dir", str(bad_dir)],
            cwd=ROOT, env=env, text=True, capture_output=True,
        )
        assert bad.returncode == 21
        bad_result = json.loads((bad_dir / "device-acceptance.json").read_text(encoding="utf-8"))
        assert bad_result["failure"] == "APK_SHA256_MISMATCH"

        emulator_dir = work / "emulator"
        write_fake_adb(fake_adb, emulator=True)
        emulator = subprocess.run(
            [sys.executable, str(HARNESS), "--apk", str(apk), "--expected-sha256", digest,
             "--expected-version-name", "0.53.35", "--expected-version-code", "88",
             "--output-dir", str(emulator_dir)],
            cwd=ROOT, env=env, text=True, capture_output=True,
        )
        assert emulator.returncode == 32
        emulator_result = json.loads((emulator_dir / "device-acceptance.json").read_text(encoding="utf-8"))
        assert emulator_result["failure"] == "EMULATOR_REJECTED_FOR_PHYSICAL_ACCEPTANCE"

    print("DEVICE_ACCEPTANCE_HARNESS_TEST_PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
