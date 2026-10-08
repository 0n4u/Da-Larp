from __future__ import annotations

import configparser
import hashlib
import re
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULES = (
    'Movement', 'GunSpam', 'Emote', 'SOCD', 'Triggerbot', 'Camlock',
    'Aimlock', 'WallHop', 'KeyRepeat', 'Recoil', 'FOV', 'CameraTurn',
    'WeaponDetection',
)
TARGETS = ('Aimlock', 'Camlock', 'Triggerbot')


def ini_file(path: Path) -> configparser.ConfigParser:
    content = path.read_text(encoding='utf-16')
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.optionxform = str
    parser.read_string(content, source=path.name)
    return parser


def local_includes(path: Path) -> list[Path]:
    relative_dir = path.parent
    resolved = []
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        m = re.match(r'^\s*#Include\s+(.+?)\s*$', line, flags=re.I)
        if not m:
            continue
        raw = m.group(1).strip().replace('\\', '/')
        if raw.lower().startswith('%a_scriptdir%'):
            raw = raw[len('%A_ScriptDir%'):].lstrip('/')
            target = (path.parent / raw).resolve()
        elif raw.lower().startswith('%a_linefile%'):
            raw = raw[len('%A_LineFile%'):]
            target = (path / raw.lstrip('/')).resolve()
        else:
            target = (relative_dir / raw).resolve()
        resolved.append(target)
    return resolved


class ReleaseChecks(unittest.TestCase):
    def test_required_entrypoints_and_binaries(self):
        for filename in (
            'Start.cmd', 'Stop.cmd', 'DaHoodSuite.ahk',
            'runtime/AutoHotkey64.exe', 'runtime/TargetScan.dll',
            'runtime/TargetScanAdvanced.dll', 'tools/SuiteGuardian.ahk',
            'tools/Start-Suite.ps1', 'devtests/ConfigRegression.ahk',
        ):
            with self.subTest(filename=filename):
                self.assertTrue((ROOT / filename).is_file())

    def test_all_ahk_includes(self):
        examined = 0
        for script in ROOT.rglob('*.ahk'):
            for dep in local_includes(script):
                with self.subTest(source=str(script.relative_to(ROOT)), dependency=str(dep)):
                    self.assertTrue(dep.is_file(), f'missing include: {dep}')
                    self.assertTrue(dep.is_relative_to(ROOT), f'include outside distribution: {dep}')
                    examined += 1
        self.assertGreaterEqual(examined, 60)

    def test_factory_is_safe_and_complete(self):
        factory = ini_file(ROOT / 'config/settings.example.ini')
        default = ini_file(ROOT / 'config/Default.ini')
        live = ini_file(ROOT / 'config/settings.ini')
        for profile in (factory, default, live):
            self.assertEqual(profile['Meta']['SchemaVersion'], '17')
            for mod in MODULES:
                self.assertEqual(profile['Modules'][mod], '0', mod)
        for profile in (factory, live):
            self.assertEqual(profile['App']['AutoLoadConfig'], '0')
        self.assertEqual(factory['App']['StartupConfig'], 'Default.ini')
        self.assertEqual(live['General']['Profile'], 'Default')

    def test_preset_keys_and_targeting_isolation(self):
        templates = ini_file(ROOT / 'config/settings.example.ini')
        required = {section: set(templates[section]) for section in templates.sections()}
        total = 0
        for path in (ROOT / 'config').glob('*.ini'):
            if path.name.lower() in ('settings.ini', 'settings.example.ini'):
                continue
            total += 1
            with self.subTest(profile=path.name):
                self.assertNotIn('silent', path.name.lower())
                cfg = ini_file(path)
                self.assertEqual(cfg['Meta']['SchemaVersion'], '17')
                self.assertEqual(cfg['General']['Master'], '1')
                self.assertTrue(cfg['General']['Profile'].strip())
                for m in MODULES:
                    self.assertIn(cfg['Modules'][m], ('0', '1'))
                active = [m for m in TARGETS if cfg['Modules'][m] == '1']
                self.assertLessEqual(len(active), 1)
                for m in active:
                    self.assertEqual(cfg[m]['Hotkey'].lower(), 'rbutton')
                for m in TARGETS:
                    self.assertEqual(cfg[m]['TargetColor'].upper(), '0X000000')
                    if m not in active:
                        self.assertEqual(cfg[m]['Hotkey'], '')
                if active:
                    self.assertEqual(cfg['Modules']['FOV'], '1')
                    self.assertEqual(cfg['FOV']['Color'].upper(), '0XFFFFFF')
                    self.assertEqual(cfg['FOV']['Thickness'], '1')
                for section in ('General', 'Modules', 'Aimlock', 'Camlock', 'Triggerbot', 'FOV'):
                    self.assertFalse(required[section] - set(cfg[section]),
                                     f'missing {section}: {required[section] - set(cfg[section])}')
        self.assertEqual(total, 23)

    def test_native_exports(self):
        for dll, api in (('TargetScan.dll','ScanPixels'),('TargetScanAdvanced.dll','ScanAdvanced')):
            path = ROOT / 'runtime' / dll
            self.assertGreater(path.stat().st_size, 1024)
            self.assertEqual(path.read_bytes()[:2], b'MZ')
            if shutil.which('objdump') is None:
                continue
            tool = subprocess.run(['objdump', '-p', str(path)], stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, text=True)
            if tool.returncode:
                self.skipTest('objdump unavailable; binary export checks require PE tools')
            self.assertRegex(tool.stdout, re.escape(api) + r'\b')

    def test_preflight_is_release_gate(self):
        launcher = (ROOT / 'tools/Start-Suite.ps1').read_text(encoding='utf-8-sig')
        helper = (ROOT / 'tools/Invoke-AhkPreflight.ps1').read_text(encoding='utf-8-sig')
        self.assertIn('ConfigRegression.ahk', launcher)
        self.assertIn('-FailOnWarning', launcher)
        self.assertIn('switch]$FailOnWarning', helper)
        self.assertLess(launcher.index('ConfigRegression.ahk'),
                        launcher.index("'tools\\Stop-SuiteProcesses.ps1'"))
        self.assertIn('preflight validation', launcher)

    def test_scanner_cleanup_on_export_error(self):
        source = (ROOT / 'lib/TargetSnapshot.ahk').read_text()
        start = source.index('static InitAdvanced()')
        end = source.index('static AdvancedFind', start)
        block = source[start:end]
        self.assertIn('FreeLibrary', block)
        self.assertIn('this.AdvancedLibrary := 0', block)
        self.assertIn('this.AdvancedScan', block)

    def test_manifest_integrity(self):
        path = ROOT / 'SHA256SUMS.txt'
        self.assertTrue(path.exists())
        hashes = {}
        for line in path.read_text().splitlines():
            digest, name = line.split('  ', 1)
            self.assertNotIn(name, hashes)
            hashes[name] = digest
        files = {x.relative_to(ROOT).as_posix(): x for x in ROOT.rglob('*')
                 if x.is_file() and x.name != 'SHA256SUMS.txt' and '__pycache__' not in x.parts and '.git' not in x.parts and all(part not in ('state','logs','backups','profiles','support') for part in x.relative_to(ROOT).parts)}
        self.assertEqual(set(hashes), set(files))
        for name, file in files.items():
            with self.subTest(name=name):
                self.assertEqual(hashlib.sha256(file.read_bytes()).hexdigest(), hashes[name])


if __name__ == '__main__':
    unittest.main(verbosity=2)
