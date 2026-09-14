#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, os, subprocess, sys, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
HARNESS = ROOT / "tools/android/device_acceptance.py"
VERIFIER = ROOT / "tools/android/verify_device_acceptance.py"

def write_fake_adb(path: Path, *, emulator: bool = False) -> None:
    qemu = "1" if emulator else "0"
    model = "sdk_gphone64_arm64" if emulator else "FixturePhone"
    fingerprint = "generic/sdk_gphone/emulator" if emulator else "fixture/vendor/device:16/test/release-keys"
    path.write_text(f'''#!/usr/bin/env python3
import sys
args=sys.argv[1:]
if args==['version']: print('Android Debug Bridge version 1.0.41'); raise SystemExit(0)
if args==['devices']: print('List of devices attached\\nFAKE123\\tdevice'); raise SystemExit(0)
if args[:2]==['-s','FAKE123']: args=args[2:]
if args[:2]==['install','-r']: print('Success'); raise SystemExit(0)
if args[:2]==['shell','getprop']:
 props={{'ro.product.manufacturer':'FixtureVendor','ro.product.model':'{model}','ro.product.name':'fixture_product','ro.product.device':'fixture_device','ro.hardware':'fixture_hw','ro.build.version.release':'16','ro.build.version.sdk':'36','ro.product.cpu.abi':'arm64-v8a','ro.build.fingerprint':'{fingerprint}','ro.kernel.qemu':'{qemu}'}}
 print(props.get(args[2],'')); raise SystemExit(0)
if args[:3]==['shell','pm','path']: print('package:/data/app/com.amir.hayattounes/base.apk'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','package']: print('Packages:\\n Package [com.amir.hayattounes]\\n versionCode=88 minSdk=24 targetSdk=35\\n versionName=0.53.35'); raise SystemExit(0)
if args[:2]==['logcat','-c']: raise SystemExit(0)
if args[:3]==['shell','am','force-stop']: raise SystemExit(0)
if args[:2]==['shell','monkey']: print('Events injected: 1'); raise SystemExit(0)
if args[:2]==['shell','pidof']: print('4242'); raise SystemExit(0)
if args[:2]==['exec-out','screencap']: sys.stdout.buffer.write(b'\\x89PNG\\r\\n\\x1a\\nfixture'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','gfxinfo']: print('---PROFILEDATA---\\nFlags,IntendedVsync,Vsync'); raise SystemExit(0)
if args[:2]==['logcat','-d']: print('Godot Engine started successfully'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','meminfo']: print('TOTAL PSS: 12345'); raise SystemExit(0)
if args[:3]==['shell','dumpsys','thermalservice']: print('Thermal Status: 0'); raise SystemExit(0)
print('UNHANDLED', args, file=sys.stderr); raise SystemExit(2)
''', encoding='utf-8')
    path.chmod(0o755)

def main() -> int:
    with tempfile.TemporaryDirectory() as td:
        work=Path(td); bindir=work/'bin'; bindir.mkdir(); apk=work/'test.apk'; apk.write_bytes(b'hayat-tounes-device-acceptance-fixture')
        digest=hashlib.sha256(apk.read_bytes()).hexdigest(); fake=bindir/'adb'; write_fake_adb(fake)
        env=os.environ.copy(); env['PATH']=str(bindir)+os.pathsep+env.get('PATH','')
        evidence=work/'evidence'
        cmd=[sys.executable,str(HARNESS),'--apk',str(apk),'--expected-sha256',digest,'--expected-version-name','0.53.35','--expected-version-code','88','--output-dir',str(evidence),'--settle-seconds','1']
        proc=subprocess.run(cmd,cwd=ROOT,env=env,text=True,capture_output=True)
        assert proc.returncode==0,(proc.stdout,proc.stderr)
        result=json.loads((evidence/'device-acceptance.json').read_text())
        assert result['schema_version']==3 and result['status']=='PASS'
        assert 'device_serial' not in result and len(result['device_serial_sha256'])==64
        assert 'build_fingerprint' not in result['device'] and len(result['device']['build_fingerprint_sha256'])==64
        assert result['checks']['evidence_integrity']=='PASS'
        assert set(result['captured_files'])=={'launch.png','logcat.txt','gfxinfo-framestats.txt','meminfo.txt','package-dump.txt','thermalservice.txt'}
        verify=subprocess.run([sys.executable,str(VERIFIER),str(evidence),'--expected-apk-sha256',digest,'--expected-version-name','0.53.35','--expected-version-code','88'],cwd=ROOT,text=True,capture_output=True)
        assert verify.returncode==0,(verify.stdout,verify.stderr)
        (evidence/'logcat.txt').write_text('tampered')
        tampered=subprocess.run([sys.executable,str(VERIFIER),str(evidence),'--expected-apk-sha256',digest,'--expected-version-name','0.53.35','--expected-version-code','88'],cwd=ROOT,text=True,capture_output=True)
        assert tampered.returncode!=0 and 'FILE_SIZE_MISMATCH:logcat.txt' in tampered.stderr
        bad=subprocess.run([sys.executable,str(HARNESS),'--apk',str(apk),'--expected-sha256','0'*64,'--output-dir',str(work/'bad')],cwd=ROOT,env=env,text=True,capture_output=True)
        assert bad.returncode==21
        write_fake_adb(fake,emulator=True)
        emu=subprocess.run([sys.executable,str(HARNESS),'--apk',str(apk),'--expected-sha256',digest,'--expected-version-name','0.53.35','--expected-version-code','88','--output-dir',str(work/'emu')],cwd=ROOT,env=env,text=True,capture_output=True)
        assert emu.returncode==32
    print('DEVICE_ACCEPTANCE_HARNESS_V3_TEST_PASS')
    return 0
if __name__=='__main__': raise SystemExit(main())
