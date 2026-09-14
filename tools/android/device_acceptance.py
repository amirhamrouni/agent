#!/usr/bin/env python3
"""Fail-closed physical Android acceptance harness for Hayat Tounes.

Installs a verified APK on a connected Android device, launches the package,
collects runtime evidence, and emits a machine-readable JSON result. It never
marks acceptance PASS unless installation, launch/PID, screenshot, log scan and
basic frame-stat collection all succeed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

PACKAGE_ID = "com.amir.hayattounes"
FATAL_PATTERNS = re.compile(
    r"FATAL EXCEPTION|AndroidRuntime.*FATAL|SIGSEGV|SIGABRT|ANR in |"
    r"SCRIPT ERROR:|Parse Error:|Failed to load script",
    re.IGNORECASE,
)


def run(cmd: list[str], *, check: bool = True, text: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=check, capture_output=True, text=text)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def adb(serial: str | None, *args: str, check: bool = True, text: bool = True) -> subprocess.CompletedProcess:
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += list(args)
    return run(cmd, check=check, text=text)


def fail(message: str, evidence: dict, output: Path, code: int) -> int:
    evidence["status"] = "FAIL"
    evidence["failure"] = message
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"ANDROID_DEVICE_ACCEPTANCE_FAIL:{message}", file=sys.stderr)
    return code


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--expected-sha256")
    parser.add_argument("--serial")
    parser.add_argument("--output-dir", type=Path, default=Path("device-acceptance-evidence"))
    parser.add_argument("--settle-seconds", type=int, default=12)
    args = parser.parse_args()

    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    result_path = output_dir / "device-acceptance.json"
    evidence: dict = {
        "schema_version": 1,
        "package_id": PACKAGE_ID,
        "apk": str(args.apk),
        "status": "INCOMPLETE",
        "checks": {},
    }

    if not args.apk.is_file():
        return fail("APK_NOT_FOUND", evidence, result_path, 20)

    actual_sha = sha256(args.apk)
    evidence["apk_sha256"] = actual_sha
    if args.expected_sha256 and actual_sha.lower() != args.expected_sha256.lower():
        return fail("APK_SHA256_MISMATCH", evidence, result_path, 21)
    evidence["checks"]["apk_sha256"] = "PASS"

    try:
        version = run(["adb", "version"]).stdout.splitlines()[0]
    except (FileNotFoundError, subprocess.CalledProcessError):
        return fail("ADB_UNAVAILABLE", evidence, result_path, 22)
    evidence["adb_version"] = version

    devices = run(["adb", "devices"]).stdout.splitlines()[1:]
    online = [line.split("\t", 1)[0] for line in devices if line.strip().endswith("\tdevice")]
    serial = args.serial or (online[0] if len(online) == 1 else None)
    if not serial:
        return fail("ANDROID_DEVICE_NOT_UNIQUELY_RESOLVED", evidence, result_path, 23)
    if serial not in online:
        return fail("ANDROID_DEVICE_NOT_ONLINE", evidence, result_path, 24)
    evidence["device_serial"] = serial

    def prop(name: str) -> str:
        return adb(serial, "shell", "getprop", name).stdout.strip()

    evidence["device"] = {
        "manufacturer": prop("ro.product.manufacturer"),
        "model": prop("ro.product.model"),
        "android_release": prop("ro.build.version.release"),
        "sdk": prop("ro.build.version.sdk"),
        "abi": prop("ro.product.cpu.abi"),
        "build_fingerprint": prop("ro.build.fingerprint"),
    }

    install = adb(serial, "install", "-r", "-t", str(args.apk), check=False)
    evidence["install_stdout"] = install.stdout.strip()
    evidence["install_stderr"] = install.stderr.strip()
    if install.returncode != 0 or "Success" not in install.stdout:
        return fail("APK_INSTALL_FAILED", evidence, result_path, 25)
    evidence["checks"]["install"] = "PASS"

    package_path = adb(serial, "shell", "pm", "path", PACKAGE_ID, check=False).stdout.strip()
    if not package_path.startswith("package:"):
        return fail("PACKAGE_NOT_INSTALLED", evidence, result_path, 26)
    evidence["package_path"] = package_path

    adb(serial, "logcat", "-c", check=False)
    adb(serial, "shell", "am", "force-stop", PACKAGE_ID, check=False)

    launch = adb(
        serial, "shell", "monkey", "-p", PACKAGE_ID, "-c",
        "android.intent.category.LAUNCHER", "1", check=False,
    )
    evidence["launch_stdout"] = launch.stdout.strip()
    if launch.returncode != 0 or "Events injected: 1" not in launch.stdout:
        return fail("APP_LAUNCH_COMMAND_FAILED", evidence, result_path, 27)

    time.sleep(max(1, args.settle_seconds))
    pid = adb(serial, "shell", "pidof", PACKAGE_ID, check=False).stdout.strip()
    if not pid:
        logcat = adb(serial, "logcat", "-d", "-v", "threadtime", check=False).stdout
        (output_dir / "logcat.txt").write_text(logcat, encoding="utf-8", errors="replace")
        return fail("APP_PROCESS_NOT_ALIVE", evidence, result_path, 28)
    evidence["pid"] = pid
    evidence["checks"]["process_alive"] = "PASS"

    screenshot = adb(serial, "exec-out", "screencap", "-p", check=False, text=False)
    screenshot_path = output_dir / "launch.png"
    if screenshot.returncode != 0 or not screenshot.stdout:
        return fail("SCREENSHOT_CAPTURE_FAILED", evidence, result_path, 29)
    screenshot_path.write_bytes(screenshot.stdout)
    evidence["checks"]["screenshot"] = "PASS"

    gfx = adb(serial, "shell", "dumpsys", "gfxinfo", PACKAGE_ID, "framestats", check=False).stdout
    (output_dir / "gfxinfo-framestats.txt").write_text(gfx, encoding="utf-8", errors="replace")
    if not gfx.strip():
        return fail("FRAMESTATS_EMPTY", evidence, result_path, 30)
    evidence["checks"]["framestats"] = "PASS"

    logcat = adb(serial, "logcat", "-d", "-v", "threadtime", check=False).stdout
    log_path = output_dir / "logcat.txt"
    log_path.write_text(logcat, encoding="utf-8", errors="replace")
    fatal_matches = sorted(set(match.group(0) for match in FATAL_PATTERNS.finditer(logcat)))
    evidence["fatal_log_matches"] = fatal_matches
    if fatal_matches:
        return fail("FATAL_RUNTIME_LOG_MATCH", evidence, result_path, 31)
    evidence["checks"]["fatal_log_scan"] = "PASS"

    meminfo = adb(serial, "shell", "dumpsys", "meminfo", PACKAGE_ID, check=False).stdout
    (output_dir / "meminfo.txt").write_text(meminfo, encoding="utf-8", errors="replace")

    evidence["status"] = "PASS"
    evidence["checks"]["launch"] = "PASS"
    evidence["captured_files"] = [
        "launch.png", "logcat.txt", "gfxinfo-framestats.txt", "meminfo.txt"
    ]
    result_path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print("ANDROID_DEVICE_ACCEPTANCE_PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
