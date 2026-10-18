# Rites and Remembrance

A Sapiens mod by **Vittorio**. GitHub owner: **VittorioJ85**.

See [the mod guide](RitesAndRemembrance/README.md),
[development notes](RitesAndRemembrance/DEVELOPMENT.md), and
[third-party notices](RitesAndRemembrance/COMPATIBILITY_NOTICES.md).

## Repository layout

- `RitesAndRemembrance/`: installable mod files, preserved from the development workspace.
- `rites-preview/`: selected tribal ceremony and UI regression tests.
- `lua_runner.py`: local Windows test runner using the installed game's Lua DLL.
- `tools/package.py`: game-independent validation and ZIP creation.

## Build

Run `python tools/package.py` with Python 3.11 or newer. The script validates
metadata and JSON and verifies every archived byte against a buffered source
snapshot. Outputs and SHA-256 checksums go into ignored `dist/`.
GitHub Actions runs this on pushes and pull requests and stores downloadable
artifacts. It does not install the mod or publish a release.

## Local runtime tests

On Windows with the respective game installed:

```powershell
python rites-preview/test_tribal_ceremony.py --edition Public
python rites-preview/test_tribal_ceremony.py --edition Unstable
```

The runner uses the existing local installation paths documented in `AGENTS.md`.
These tests cover ceremony behavior and UI mocks, not the full mod test suite.
Game files and Family Tree integration fixtures are not included in this repo.
CI packaging checks do not establish Lua runtime or in-engine correctness.
Run in-game checks separately in a disposable world.

## Git workflow

1. Fetch/pull changes before starting work.
2. Create a branch, such as `codex/fix-ceremony`.
3. Edit source, run the applicable tests, and review the diff.
4. Commit a focused change, then push it.
5. Review the GitHub checks and merge the pull request.

This repository began as a byte-verified snapshot of the original project.
There is no automatic synchronization with that original folder. Choose one
working copy for future edits; do not edit both copies independently.
Existing install scripts in the original workspace still use that workspace.

Keep this repository private initially. Existing third-party notices and
reference snapshots are retained; no new license or redistribution grant is
implied. Review provenance before any public release.
