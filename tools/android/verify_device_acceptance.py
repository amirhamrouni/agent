#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

PACKAGE_ID = "com.amir.hayattounes"
SCHEMA_VERSION = 3
REQUIRED_FILES = ("launch.png", "logcat.txt", "gfxinfo-framestats.txt", "meminfo.txt", "package-dump.txt", "thermalservice.txt")
REQUIRED_PASS_CHECKS = ("apk_sha256", "physical_device", "install", "installed_version", "process_alive", "screenshot", "framestats", "fatal_log_scan", "launch", "evidence_integrity")
FATAL_PATTERNS = re.compile(r"FATAL EXCEPTION|AndroidRuntime.*FATAL|SIGSEGV|SIGABRT|ANR in |SCRIPT ERROR:|Parse Error:|Failed to load script", re.IGNORECASE)
HEX64 = re.compile(r"^[0-9a-f]{64}$")

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def sha256_text(value: str) -> str: return hashlib.sha256(value.encode("utf-8")).hexdigest()
def binding(apk_sha: str, version_name: str, version_code: int, serial_sha: str) -> str: return sha256_text("|".join([PACKAGE_ID, apk_sha.lower(), version_name, str(version_code), serial_sha.lower()]))
def die(message: str) -> int:
    print(f"DEVICE_ACCEPTANCE_EVIDENCE_FAIL:{message}", file=sys.stderr)
    return 2

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("evidence_dir", type=Path)
    p.add_argument("--expected-apk-sha256", required=True)
    p.add_argument("--expected-version-name", required=True)
    p.add_argument("--expected-version-code", required=True, type=int)
    args = p.parse_args()
    root = args.evidence_dir
    result_path = root / "device-acceptance.json"
    if not result_path.is_file(): return die("MISSING_DEVICE_ACCEPTANCE_JSON")
    try: data = json.loads(result_path.read_text(encoding="utf-8"))
    except Exception: return die("INVALID_DEVICE_ACCEPTANCE_JSON")
    if data.get("schema_version") != SCHEMA_VERSION: return die("SCHEMA_VERSION_MISMATCH")
    if data.get("status") != "PASS": return die("ACCEPTANCE_STATUS_NOT_PASS")
    if data.get("package_id") != PACKAGE_ID: return die("PACKAGE_ID_MISMATCH")
    apk_sha = str(data.get("apk_sha256", "")).lower()
    if apk_sha != args.expected_apk_sha256.lower() or not HEX64.fullmatch(apk_sha): return die("APK_SHA256_MISMATCH")
    expected = data.get("expected", {})
    if expected.get("apk_sha256", "").lower() != apk_sha: return die("RECORDED_EXPECTED_APK_SHA256_MISMATCH")
    if expected.get("version_name") != args.expected_version_name or expected.get("version_code") != args.expected_version_code: return die("RECORDED_EXPECTED_VERSION_MISMATCH")
    installed = data.get("installed_package", {})
    if installed.get("version_name") != args.expected_version_name or installed.get("version_code") != args.expected_version_code: return die("INSTALLED_VERSION_MISMATCH")
    device = data.get("device", {})
    if device.get("emulator_detected") is not False: return die("DEVICE_NOT_PROVEN_PHYSICAL")
    serial_sha = str(data.get("device_serial_sha256", "")).lower()
    if not HEX64.fullmatch(serial_sha): return die("DEVICE_SERIAL_HASH_INVALID")
    if "device_serial" in data: return die("RAW_DEVICE_SERIAL_PRESENT")
    fingerprint_sha = str(device.get("build_fingerprint_sha256", "")).lower()
    if not HEX64.fullmatch(fingerprint_sha): return die("BUILD_FINGERPRINT_HASH_INVALID")
    if "build_fingerprint" in device: return die("RAW_BUILD_FINGERPRINT_PRESENT")
    checks = data.get("checks", {})
    for key in REQUIRED_PASS_CHECKS:
        if checks.get(key) != "PASS": return die(f"CHECK_NOT_PASS:{key}")
    if data.get("fatal_log_matches") not in ([], None): return die("RECORDED_FATAL_LOG_MATCH")
    captured = data.get("captured_files", {})
    for name in REQUIRED_FILES:
        path = root / name; meta = captured.get(name)
        if not path.is_file() or path.stat().st_size == 0: return die(f"MISSING_OR_EMPTY_FILE:{name}")
        if not isinstance(meta, dict): return die(f"MISSING_FILE_METADATA:{name}")
        if meta.get("size_bytes") != path.stat().st_size: return die(f"FILE_SIZE_MISMATCH:{name}")
        if meta.get("sha256") != sha256(path): return die(f"FILE_SHA256_MISMATCH:{name}")
    if not (root / "launch.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n"): return die("SCREENSHOT_NOT_PNG")
    logcat = (root / "logcat.txt").read_text(encoding="utf-8", errors="replace")
    if FATAL_PATTERNS.search(logcat): return die("FATAL_PATTERN_IN_LOGCAT")
    package_dump = (root / "package-dump.txt").read_text(encoding="utf-8", errors="replace")
    if f"versionName={args.expected_version_name}" not in package_dump or f"versionCode={args.expected_version_code}" not in package_dump: return die("PACKAGE_DUMP_VERSION_MISMATCH")
    if data.get("acceptance_binding_sha256") != binding(apk_sha, args.expected_version_name, args.expected_version_code, serial_sha): return die("ACCEPTANCE_BINDING_MISMATCH")
    print("DEVICE_ACCEPTANCE_EVIDENCE_PASS")
    return 0

if __name__ == "__main__": raise SystemExit(main())
