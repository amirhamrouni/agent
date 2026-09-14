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


def main() -> int:
    with tempfile.TemporaryDirectory() as td:
        work = Path(td)
        bin_dir = work / "bin"
        bin_dir.mkdir()
        apk = work / "test.apk"
        apk.write_bytes(b"hayat-tounes-device-acceptance-fixture")
        digest = hashlib.sha256(apk.read_bytes()).hexdigest()

        fake_adb = bin_dir / "adb"
        fake_adb.write_text(
            """#!/usr/bin/env python3
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
 props={'ro.product.manufacturer':'OpenAI','ro.product.model':'FixturePhone','ro.build.version.release':'16','ro.build.version.sdk':'36','ro.product.cpu.abi':'arm64-v8a','ro.build.fingerprint':'fixture/fingerprint'}
 print(props.get(args[2],'')); raise SystemExit(0)
if args[:3]==['shell','pm','path']:
 print('package:/data/app/com.amir.hayattounes/base.apk'); raise SystemExit(0)
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
print('UNHANDLED', args, file=sys.stderr); raise SystemExit(2)
""",
            encoding="utf-8",
        )
        fake_adb.chmod(0o755)

        evidence_dir = work / "evidence"
        env = os.environ.copy()
        env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")
        proc = subprocess.run(
            [
                sys.executable,
                str(HARNESS),
                "--apk", str(apk),
                "--expected-sha256", digest,
                "--output-dir", str(evidence_dir),
                "--settle-seconds", "1",
            ],
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
        )
        if proc.returncode != 0:
            print(proc.stdout)
            print(proc.stderr, file=sys.stderr)
            return proc.returncode
        if "ANDROID_DEVICE_ACCEPTANCE_PASS" not in proc.stdout:
            raise SystemExit("missing PASS marker")
        result = json.loads((evidence_dir / "device-acceptance.json").read_text(encoding="utf-8"))
        assert result["status"] == "PASS"
        assert result["apk_sha256"] == digest
        assert result["device_serial"] == "FAKE123"
        assert result["checks"]["install"] == "PASS"
        assert result["checks"]["process_alive"] == "PASS"
        assert (evidence_dir / "launch.png").is_file()
        assert (evidence_dir / "logcat.txt").is_file()
        assert (evidence_dir / "gfxinfo-framestats.txt").is_file()
        assert (evidence_dir / "meminfo.txt").is_file()

        bad = subprocess.run(
            [sys.executable, str(HARNESS), "--apk", str(apk), "--expected-sha256", "0" * 64,
             "--output-dir", str(work / "bad")],
            cwd=ROOT, env=env, text=True, capture_output=True,
        )
        assert bad.returncode == 21
        bad_result = json.loads((work / "bad/device-acceptance.json").read_text(encoding="utf-8"))
        assert bad_result["status"] == "FAIL"
        assert bad_result["failure"] == "APK_SHA256_MISMATCH"

    print("DEVICE_ACCEPTANCE_HARNESS_TEST_PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
