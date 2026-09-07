# Graphify + RTK

- Before >3 manual file reads, check if `graphify-out/graph.json` exists. If so, use the graphify skill for architecture/dependency/caller questions instead of reading files individually.
- Use `skill: graphify` and run `graphify query` for codebase exploration questions.
- Verify `rtk --version` before using rtk. If missing, install via `scripts/install-rtk.ps1` (Windows) or `scripts/install-rtk.sh` (Linux/macOS) per `rules/auto-install-tools.md`.
- Prefer `rtk` wrapper for shell commands; fall back to raw shell only if rtk is unavailable.
- Do not add cotrex anywhere.