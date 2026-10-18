"""Validate and package a stable source snapshot without game dependencies."""
from pathlib import Path
import hashlib
import json
import re
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'RitesAndRemembrance'

def main():
    snapshot = {}
    for path in sorted(SOURCE.rglob('*')):
        if path.is_symlink():
            raise ValueError(f'Symlinks are not supported: {path}')
        if path.is_file():
            if path.suffix.lower() in {'.dll', '.exe', '.dmp', '.log', '.zip'} or path.name == '.env':
                raise ValueError(f'Unexpected distribution file: {path}')
            snapshot[path.relative_to(ROOT).as_posix()] = path.read_bytes()
    metadata = snapshot['RitesAndRemembrance/modInfo.lua'].decode('utf-8')
    match = re.search(r'version\s*=\s*"(\d+\.\d+\.\d+)"', metadata)
    if not match or not re.search(r'developer\s*=\s*"Vittorio"', metadata):
        raise ValueError('Expected semantic version and developer Vittorio.')
    if len(snapshot['RitesAndRemembrance/preview.png']) >= 1_000_000:
        raise ValueError('Workshop preview must be smaller than 1 MB.')
    for name, data in snapshot.items():
        if name.endswith('.json'):
            json.loads(data)
    target = ROOT / 'dist' / f'RitesAndRemembrance-{match[1]}.zip'
    target.parent.mkdir(exist_ok=True)
    with ZipFile(target, 'w', ZIP_DEFLATED) as archive:
        for name, data in snapshot.items():
            archive.writestr(name, data)
    with ZipFile(target) as archive:
        if set(archive.namelist()) != set(snapshot) or archive.testzip():
            raise ValueError('Archive validation failed.')
        for name, data in snapshot.items():
            if archive.read(name) != data:
                raise ValueError(f'Archive byte mismatch: {name}')
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix('.zip.sha256').write_text(f'{digest}  {target.name}\n', encoding='ascii')
    print(f'PASS: {len(snapshot)} files packaged and byte-verified: {target}')

if __name__ == '__main__':
    main()
