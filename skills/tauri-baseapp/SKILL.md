---
name: tauri-baseapp
description: "Scaffold a new Tauri v2 + React + TypeScript project from BaseApp template without git history. Triggers on: new tauri project, tauri starter, baseapp, tauri template, tauri base, tauri scaffold from BaseApp."
---

# Tauri BaseApp Starter

Scaffold a new Tauri v2 desktop app from `https://github.com/pamod-madubashana/BaseApp` as a GitHub **template** — new repo starts with files only, single initial commit, no history, no fork link.

Generate URL: `https://github.com/pamod-madubashana/BaseApp/generate`.
BaseApp is production-ready: Tauri v2 + React 19 + TypeScript + Vite, signed self-updater (`src/components/Updater.tsx` + `tauri-plugin-updater`), 3-OS `release.yml` + `verify.yml`.

## What You Must Do When Invoked

1. Ask for: **new app name** (e.g. `myapp`), **identifier** (e.g. `com.company.myapp`), **target dir**, **new GitHub `owner/repo`** for updater endpoint.
2. Scaffold without history (Step 1).
3. Rebrand + rewire updater (Steps 2-3).
4. Init fresh git, install, verify (Steps 4-5).

---

## Step 1 — Scaffold From Template (no history)

Never `git clone` BaseApp directly, never fork. Pick one:

### Option A — GitHub template (preferred, true template flow)

Web: open `https://github.com/pamod-madubashana/BaseApp/generate` (or BaseApp page → **Use this template**) → pick owner/name → Create repository → Clone it.

```sh
# CLI equivalent:
gh repo create myapp --template pamod-madubashana/BaseApp --private --clone
cd myapp
```

Result: fresh repo with BaseApp files, 1 squashed initial commit, no shared history, no fork badge. Upstream changes are NOT auto-merged — re-apply manually if needed.

### Option B — degit (no git at all, no GitHub repo yet)

```sh
npx degit pamod-madubashana/BaseApp myapp
cd myapp
```

### Option C — tarball (no git binary needed)

```sh
# bash
curl -L https://github.com/pamod-madubashana/BaseApp/archive/refs/heads/main.tar.gz | tar -xz --strip-components=1 -C ./myapp
```

```powershell
# PowerShell (Windows)
$zip = "$env:TEMP\BaseApp.zip"
Invoke-WebRequest -Uri "https://github.com/pamod-madubashana/BaseApp/archive/refs/heads/main.zip" -OutFile $zip
Expand-Archive $zip -DestinationPath "$env:TEMP\BaseApp-tmp" -Force
Copy-Item "$env:TEMP\BaseApp-tmp\BaseApp-main\*" -Destination ".\myapp" -Recurse -Force
```

### Option D — shallow clone then strip (last resort)

```sh
git clone --depth 1 https://github.com/pamod-madubashana/BaseApp.git myapp
cd myapp
rm -rf .git   # PowerShell: Remove-Item -Recurse -Force .git
```

Verify: `myapp/.git` must NOT exist after this step.

---

## Step 2 — Rebrand (5 files)

Assume `APPNAME=myapp`, `IDENT=com.company.myapp`, `REPO=owner/repo`, version `0.1.0`.

1. **`package.json`** — `name` → `myapp`, `version` → `0.1.0`.
2. **`src-tauri/tauri.conf.json`**:
   - `productName` → `myapp`, `identifier` → `com.company.myapp`, `version` → `0.1.0`
   - `app.windows[0].title` → `myapp`
   - `plugins.updater.endpoints` → `["https://github.com/owner/repo/releases/latest/download/latest.json"]`
   - `plugins.updater.pubkey` → replaced in Step 3 (don't keep BaseApp key)
3. **`src-tauri/Cargo.toml`** — `[package] name` → `myapp`, `version` → `0.1.0`; `[lib] name` → `myapp_lib`.
4. **`index.html`** — `<title>` → app name.
5. **Icons (optional but recommended)** — replace `src-tauri/icons/` via `npm run tauri icon path/to/icon.png`.

Do NOT touch: `vite.config.ts` (port 1420 + `src-tauri` ignore), `src-tauri/capabilities/default.json` (`core:default`, `opener:default`, `updater:default`), `src/components/Updater.tsx` logic, `.github/workflows/` logic — only endpoint URLs inside them if hardcoded.

---

## Step 3 — New Updater Keypair (mandatory)

BaseApp's `pubkey` belongs to its author. Every new app needs its own:

```sh
cd myapp
npm install
npx tauri signer generate -w ~/.tauri/myapp.key
# prints: pubkey + private key path
```

- Paste new `pubkey` into `src-tauri/tauri.conf.json` → `plugins.updater.pubkey`.
- Save private key content as GitHub secret: repo Settings → Secrets → `TAURI_SIGNING_PRIVATE_KEY` = contents of `~/.tauri/myapp.key`.
- `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` only if you set a password during generate.

Without this, `latest.json` signature verification fails and auto-update never installs.

---

## Step 4 — Fresh Git + Install + Verify

```sh
cd myapp
git init -b main
git add -A
git commit -m "feat: scaffold from BaseApp template"
npm install
npx tsc --noEmit
npm run tauri dev     # vite on 1420 + Tauri window
```

Rust checks (matches `verify.yml`):

```sh
cargo fmt --check   # run inside src-tauri/
cargo check         # run inside src-tauri/
```

Linux build deps: `sudo apt-get install -y libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf`.

---

## Step 5 — Release Flow (already wired)

`release.yml` jobs: `validate` (SemVer normalize) → `bump-version` (updates `package.json`, `package-lock.json`, `tauri.conf.json`, `Cargo.toml`, commits `chore(release): vX.Y.Z`) → `build` matrix (Windows x86_64, Linux x86_64, macOS aarch64 via `tauri-action@v0`) → `publish` (`ncipollo/release-action@v1`).

Trigger:

```sh
gh workflow run Release -f version=0.1.0
# or: git tag v0.1.0 && git push origin v0.1.0
```

Artifacts per OS: Windows `*.msi` + `*-setup.exe` + `myapp-<ver>-portable.exe`, Linux `*.deb`/`*.rpm`/`*.AppImage`, macOS `*.dmg`, plus `latest.json` + `.sig` for the updater. `Updater.tsx` states: `checking` (hidden) → `available` → `downloading` (progress %) → `installing` → `ready` (restart) / `error` (retry).

---

## Verification Checklist

- [ ] `myapp/.git/log` does NOT contain BaseApp commits (`git log` shows 1 commit)
- [ ] `tauri.conf.json` endpoint points to new `owner/repo`, `pubkey` is new
- [ ] `package.json` + `Cargo.toml` + `tauri.conf.json` versions match
- [ ] `npx tsc --noEmit` clean, `npm run tauri build` produces `src-tauri/target/release/bundle/`
- [ ] `TAURI_SIGNING_PRIVATE_KEY` secret set on new repo

## Common Pitfalls

1. Kept `.git` — full history + wrong remote. Always delete, `git init` fresh, `gh repo create` for new remote.
2. Kept BaseApp `pubkey`/endpoint — updater checks old repo and fails signature. Regenerate per app.
3. Forgot 1 of 4 version files — `release.yml` `publish` job errors on tag-vs-file mismatch.
4. `port 1420 in use` — `strictPort: true` fails fast; kill other Vite/Tauri process.
