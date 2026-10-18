"""Tribal ceremony behavior tests against the selected native Lua runtime."""
from pathlib import Path
import json
import os
import sys
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--edition', choices=('Public', 'Unstable'))
args = parser.parse_args()
if args.edition:
    os.environ['SAPIENS_GAME_DIR'] = 'D:/Steam/steamapps/common/' + ('Sapiens_NICHT_BETA' if args.edition == 'Public' else 'Sapiens')
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from lua_runner import run, GAME
print(f'Tribal ceremony tests: {GAME}', flush=True)
os.chdir(GAME)  # ffi.load('SPCommon') uses the native process working directory.
for script in ('test_tribal_ceremony.lua', 'test_ceremony_ui.lua'):
    run('ROOT=' + json.dumps(ROOT.as_posix()) + '\nGAME=' + json.dumps(GAME.as_posix()) +
        '\ndofile(ROOT.."/rites-preview/' + script + '")')
