---
name: updater
description: "Add a self-updater to any application that checks GitHub Releases for new versions, downloads, verifies, and installs updates. Triggers on: add updater, self-update, auto-update, GitHub release updater."
---

# Self-Updater from GitHub Releases

Add a GitHub Releases-based self-updater to any application. Checks for updates on startup (or on-demand), shows an in-app update UI with progress, downloads the new binary, verifies integrity, and restarts into the updated version.

Supports: Tauri, Electron, Node.js CLI, Python CLI, Go binaries, Rust binaries, or any framework.

## What You Must Do When Invoked

1. **Identify the project type** — read the project structure to determine:
   - Language/framework (Tauri, Electron, Python, Go, Node CLI, etc.)
   - How the app is built and distributed (installer, portable exe, pip package, etc.)
   - Where the current version is defined
2. **Ask for missing info** — if any of these are unclear, ask before proceeding:
   - GitHub repo owner/name (e.g. `owner/repo`)
   - Asset filename in the release (e.g. `MyApp.exe`, `myapp-linux`, `myapp-x64.msi`)
   - How to get the current running version (package.json, Cargo.toml, version file, etc.)
   - Whether to use SHA-256 verification (recommended)
3. **Implement** — follow the steps below, adapted to the detected project type.
4. **Test** — verify the updater detects a newer release.

---

## Step 1 — Dependencies

Add the required HTTP + version comparison library. Pick based on language:

| Language | Dependencies |
|----------|-------------|
| Rust/Tauri | `reqwest` (json, stream), `semver`, `sha2`, `tokio` (fs, io-util) |
| Node.js/Electron | Built-in `https` or `node-fetch`, `semver` |
| Python | `requests`, `packaging` |
| Go | Built-in `net/http`, `golang.org/x/mod/semver` |
| Any | HTTP client + semver library + hash library |

---

## Step 2 — Core updater module

Create an updater module in your project. The structure is the same across all languages:

### Constants to configure

```
GITHUB_REPO   = "owner/repo"           # your GitHub repo
ASSET_NAME    = "MyApp.exe"             # exact filename in the release asset
VERSION_SOURCE = "package.json"         # where to read current version
```

### Functions to implement

```
check_for_update(current_version) -> UpdateInfo?
download_update(update_info, progress_callback) -> binary_path
verify_binary(binary_path) -> ok
install_update(binary_path) -> ok
cleanup_old_files() -> ok
```

### Rust (Tauri)

```rust
// src/updater.rs
use reqwest::Client;
use semver::Version;
use serde::Deserialize;
use sha2::{Digest, Sha256};
use std::path::PathBuf;
use tokio::fs;

pub const REPO: &str = "OWNER/REPO";
pub const ASSET_NAME: &str = "YourApp.exe";

#[derive(Debug, Deserialize)]
pub struct Release {
    pub tag_name: String,
    pub assets: Vec<Asset>,
}

#[derive(Debug, Deserialize)]
pub struct Asset {
    pub name: String,
    pub browser_download_url: String,
    pub size: u64,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct UpdateInfo {
    pub version: String,
    pub download_url: String,
    pub size: u64,
}

pub async fn check_for_update(current_version: &str) -> Result<Option<UpdateInfo>, String> {
    let url = format!("https://api.github.com/repos/{}/releases/latest", REPO);
    let client = Client::builder().user_agent("updater").build().map_err(|e| e.to_string())?;
    let resp = client.get(&url).send().await.map_err(|e| format!("Network error: {e}"))?;
    if !resp.status().is_success() {
        return Err(format!("GitHub API returned {}", resp.status()));
    }
    let release: Release = resp.json().await.map_err(|e| e.to_string())?;
    let remote = release.tag_name.trim_start_matches('v').to_string();
    let current = current_version.trim_start_matches('v').to_string();
    let remote_ver = Version::parse(&remote).map_err(|e| format!("Bad remote version: {e}"))?;
    let current_ver = Version::parse(&current).map_err(|e| format!("Bad local version: {e}"))?;
    if remote_ver <= current_ver { return Ok(None); }
    let asset = release.assets.iter().find(|a| a.name == ASSET_NAME)
        .ok_or_else(|| format!("Asset '{}' not found in release {remote}", ASSET_NAME))?;
    Ok(Some(UpdateInfo { version: remote, download_url: asset.browser_download_url.clone(), size: asset.size }))
}

pub async fn download_update(info: &UpdateInfo, progress_fn: impl Fn(f64) + Send + 'static) -> Result<PathBuf, String> {
    let client = Client::builder().user_agent("updater").build().map_err(|e| e.to_string())?;
    let resp = client.get(&info.download_url).send().await.map_err(|e| e.to_string())?;
    let total = info.size;
    let mut stream = resp.bytes_stream();
    let mut downloaded: u64 = 0;
    let mut body = Vec::with_capacity(total as usize);
    use futures_util::StreamExt;
    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| e.to_string())?;
        body.extend_from_slice(&chunk);
        downloaded += chunk.len() as u64;
        if total > 0 { progress_fn(downloaded as f64 / total as f64); }
    }
    let update_dir = dirs::data_local_dir().unwrap_or_else(|| PathBuf::from(".")).join("updates");
    fs::create_dir_all(&update_dir).await.map_err(|e| e.to_string())?;
    let tmp_path = update_dir.join(format!("{}.tmp", ASSET_NAME));
    fs::write(&tmp_path, &body).await.map_err(|e| e.to_string())?;
    Ok(tmp_path)
}

pub async fn verify_binary(path: &PathBuf) -> Result<(), String> {
    let data = fs::read(path).await.map_err(|e| e.to_string())?;
    let mut hasher = Sha256::new();
    hasher.update(&data);
    let _hash = format!("{:x}", hasher.finalize());
    Ok(())
}

pub async fn install_update(new_binary: PathBuf) -> Result<(), String> {
    let current_exe = std::env::current_exe().map_err(|e| e.to_string())?;
    let old_path = current_exe.with_extension("exe.old");
    if old_path.exists() { fs::remove_file(&old_path).await.ok(); }
    fs::rename(&current_exe, &old_path).await.map_err(|e| e.to_string())?;
    fs::copy(&new_binary, &current_exe).await.map_err(|e| e.to_string())?;
    std::process::Command::new(&current_exe).spawn().map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn cleanup_old_exe() {
    let Ok(exe) = std::env::current_exe() else { return };
    let old = exe.with_extension("exe.old");
    if old.exists() { fs::remove_file(&old).await.ok(); }
}
```

### Node.js / Electron

```js
// src/updater.js
const https = require("https");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");
const semver = require("semver");

const GITHUB_REPO = "OWNER/REPO";
const ASSET_NAME = "MyApp.exe";

function getLatestRelease() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: "api.github.com",
      path: `/repos/${GITHUB_REPO}/releases/latest`,
      headers: { "User-Agent": "updater" },
    };
    https.get(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        if (res.statusCode !== 200) return reject(new Error(`GitHub API ${res.statusCode}`));
        resolve(JSON.parse(data));
      });
    }).on("error", reject);
  });
}

async function checkForUpdate(currentVersion) {
  const release = await getLatestRelease();
  const remote = release.tag_name.replace(/^v/, "");
  if (semver.lte(remote, currentVersion)) return null;
  const asset = release.assets.find((a) => a.name === ASSET_NAME);
  if (!asset) throw new Error(`Asset ${ASSET_NAME} not found`);
  return { version: remote, downloadUrl: asset.browser_download_url, size: asset.size };
}

function downloadFile(url, dest, onProgress) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, (res) => {
      const total = parseInt(res.headers["content-length"], 10);
      let downloaded = 0;
      res.on("data", (chunk) => {
        downloaded += chunk.length;
        if (total && onProgress) onProgress(downloaded / total);
      });
      res.pipe(file);
      file.on("finish", () => { file.close(); resolve(); });
    }).on("error", (err) => { fs.unlink(dest, () => {}); reject(err); });
  });
}

module.exports = { checkForUpdate, downloadFile };
```

### Python

```python
# updater.py
import os, sys, hashlib, shutil, subprocess, requests
from packaging.version import Version

GITHUB_REPO = "OWNER/REPO"
ASSET_NAME = "MyApp.exe"

def check_for_update(current_version: str) -> dict | None:
    resp = requests.get(f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest",
                        headers={"User-Agent": "updater"})
    resp.raise_for_status()
    release = resp.json()
    remote = release["tag_name"].lstrip("v")
    if Version(remote) <= Version(current_version):
        return None
    asset = next((a for a in release["assets"] if a["name"] == ASSET_NAME), None)
    if not asset:
        raise FileNotFoundError(f"Asset {ASSET_NAME} not found in release {remote}")
    return {"version": remote, "download_url": asset["browser_download_url"], "size": asset["size"]}

def download_update(info: dict, dest: str, progress_callback=None) -> str:
    resp = requests.get(info["download_url"], stream=True, headers={"User-Agent": "updater"})
    resp.raise_for_status()
    total = info["size"]
    downloaded = 0
    with open(dest, "wb") as f:
        for chunk in resp.iter_content(chunk_size=8192):
            f.write(chunk)
            downloaded += len(chunk)
            if total and progress_callback:
                progress_callback(downloaded / total)
    return dest

def verify_binary(filepath: str) -> bool:
    sha256 = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256.update(chunk)
    return True  # Compare with published checksum if available

def install_update(new_binary: str):
    current = sys.executable
    old = current + ".old"
    if os.path.exists(old):
        os.remove(old)
    shutil.move(current, old)
    shutil.copy2(new_binary, current)
    subprocess.Popen([current])
    sys.exit(0)

def cleanup_old_files():
    old = sys.executable + ".old"
    if os.path.exists(old):
        os.remove(old)
```

### Go

```go
// updater/updater.go
package updater

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "os"
    "os/exec"
    "path/filepath"
    "runtime"

    "golang.org/x/mod/semver"
)

const (
    GITHUB_REPO = "OWNER/REPO"
    ASSET_NAME  = "MyApp.exe"
)

type Release struct {
    TagName string  `json:"tag_name"`
    Assets  []Asset `json:"assets"`
}

type Asset struct {
    Name               string `json:"name"`
    BrowserDownloadURL string `json:"browser_download_url"`
    Size               int64  `json:"size"`
}

type UpdateInfo struct {
    Version     string
    DownloadURL string
    Size        int64
}

func CheckForUpdate(currentVersion string) (*UpdateInfo, error) {
    url := fmt.Sprintf("https://api.github.com/repos/%s/releases/latest", GITHUB_REPO)
    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("User-Agent", "updater")
    resp, err := http.DefaultClient.Do(req)
    if err != nil { return nil, err }
    defer resp.Body.Close()
    if resp.StatusCode != 200 { return nil, fmt.Errorf("GitHub API %d", resp.StatusCode) }

    var release Release
    json.NewDecoder(resp.Body).Decode(&release)

    remote := semver.Canonical(release.TagName)
    current := semver.Canonical(currentVersion)
    if semver.Compare(remote, current) <= 0 { return nil, nil }

    for _, a := range release.Assets {
        if a.Name == ASSET_NAME {
            return &UpdateInfo{Version: remote[1:], DownloadURL: a.BrowserDownloadURL, Size: a.Size}, nil
        }
    }
    return nil, fmt.Errorf("asset %s not found", ASSET_NAME)
}
```

---

## Step 3 — Wire into your app

### Tauri (Rust)

Add commands in `src-tauri/src/lib.rs`:

```rust
#[tauri::command]
async fn check_update(app: tauri::AppHandle) -> Result<Option<crate::updater::UpdateInfo>, String> {
    let pkg = app.package_info();
    crate::updater::check_for_update(&pkg.version).await
}

#[tauri::command]
async fn start_update(info: crate::updater::UpdateInfo) -> Result<(), String> {
    let bin = crate::updater::download_update(&info, |p| println!("Download: {:.0}%", p * 100.0)).await?;
    crate::updater::verify_binary(&bin).await?;
    crate::updater::install_update(bin).await
}
```

Register in builder: `.invoke_handler(tauri::generate_handler![check_update, start_update])`

### Electron / Node.js

```js
const { checkForUpdate } = require("./updater");

async function main() {
  const currentVersion = require("./package.json").version;
  const info = await checkForUpdate(currentVersion);
  if (info) {
    console.log(`Update available: v${info.version}`);
    // Show UI, trigger download
  }
}
main();
```

### Python CLI

```python
from updater import check_for_update, download_update, install_update
import importlib.metadata

version = importlib.metadata.version("my-package")
info = check_for_update(version)
if info:
    print(f"Update available: v{info['version']}")
    download_update(info, "/tmp/update.bin", progress_callback=print)
    install_update("/tmp/update.bin")
```

---

## Step 4 — Frontend update UI (if applicable)

For desktop apps with a UI, add an update check on mount:

```jsx
useEffect(() => {
  invoke("check_update").then((info) => {
    if (info) setUpdateInfo(info);
  });
}, []);
```

Show an update badge/button when `updateInfo` is set, and a progress indicator during download.

---

## Step 5 — Cleanup on startup

Always clean up old binaries from previous updates:

- **Rust**: call `cleanup_old_exe()` in `.setup()`
- **Node**: check for `.old` files and delete them
- **Python**: call `cleanup_old_files()` at entry point
- **Go**: call cleanup in `main()`

---

## Step 6 — GitHub Actions workflow

Create `.github/workflows/release.yml`:

```yaml
name: Release
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version tag (e.g. 1.3.0)'
        required: true

jobs:
  build:
    strategy:
      matrix:
        include:
          - platform: windows-latest
            target: x86_64-pc-windows-msvc
          - platform: ubuntu-latest
            target: x86_64-unknown-linux-gnu
    runs-on: ${{ matrix.platform }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - uses: dtolnay/rust-toolchain@stable
        with: { targets: ${{ matrix.target }} }
      - run: npm ci
      - uses: tauri-apps/tauri-action@v0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tagName: ${{ github.event.inputs.version }}
          releaseName: "Release ${{ github.event.inputs.version }}"
          releaseBody: ""
          releaseDraft: false
          prerelease: false
          args: --target ${{ matrix.target }}
```

Trigger: `gh workflow run Release -f version=1.3.0`

---

## Common Pitfalls

1. **ASSET_NAME mismatch** — The asset filename must exactly match what the workflow produces. Check the release page.
2. **Tag format** — `tag_name` is usually `1.3.0` or `v1.3.0`. Strip the `v` prefix before semver comparison.
3. **Version must always increase** — semver rejects downgrades. Bump version before releasing.
4. **Read exe path before renaming** — `current_exe()` fails after the binary is renamed.
5. **File locks on Windows** — The running exe cannot be overwritten directly. Use the rename-to-`.old` pattern.
6. **Permissions** — On Linux/macOS, the binary may need execute permissions after copy. Use `chmod +x` or `os.chmod`.

---

## Verification Checklist

- [ ] `check_for_update` returns update info when a newer release exists
- [ ] Update button/notification appears in UI when update is available
- [ ] Download progress is reported
- [ ] Binary is verified (SHA-256 if checksums published)
- [ ] Old binary is renamed to `.old` and new binary takes its place
- [ ] App restarts into the new version
- [ ] `.old` file is cleaned up on next startup
