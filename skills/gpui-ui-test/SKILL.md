---
name: gpui-ui-test
description: "Drive and visually verify a native GPUI (Rust) Windows app with real mouse clicks, cursor moves, and PNG captures, then compare frames to mockups. Triggers on: test UI, capture app, click button, screenshot GPUI, verify layout, compare mock, focus test, PrintWindow."
---

# GPUI UI Test (click / capture / compare)

Drive a native GPUI Windows app with real input, capture frames, and compare against visual truth (mock/ screenshots). Scripts live in this repo under `scripts/`.

## Prerequisites

- Windows + PowerShell 5.1 (no `&&`; use `;` or `if ($?)`)
- App process has a main window (default scripts assume process name **`xd-store`** — change it in the scripts if needed)
- Mock / reference PNGs as the expected visual state

## Scripts

All paths below assume scripts dir is on disk (copy or call by absolute path).

| Script | Purpose |
|--------|---------|
| `scripts/pw_cap.ps1` | **Primary screenshot** — PrintWindow + 1px size jiggle to force a fresh present |
| `scripts/cap.ps1` | Screen grab of the window rect (foreground + topmost briefly) |
| `scripts/click.ps1` | **Real physical click** (`SetCursorPos` + `mouse_event`) |
| `scripts/msg.ps1` | Synthetic `PostMessage` move/click/wheel (client coords; no cursor move) |
| `scripts/wstat.ps1` | Window state; restore; move; stepwise drag; double-click; right-click |
| `scripts/shot_app.ps1` | Cold start → raise → screen capture → stop process |
| `scripts/dblprobe.ps1` | Ad-hoc double-click probe |

## Coordinate systems

- **Window outer rect** (GetWindowRect) includes invisible borders: typically **L/R/B = 8, top = 1**.
- **Client** size for a standard frame ≈ outer − borders. Prefer: client = screenshot_pixel − (8, 1) when reading from a capture taken at outer origin.
- `click.ps1 -RelX/-RelY` are **relative to the window outer origin**, not client.
- `msg.ps1 -ClickX/-ClickY` and `wstat.ps1` action coords are **client-relative** (wstat converts via outer + offset as implemented).
- Stable test geometry: outer `(16,16)` size `1376×909` → client `1360×900`. Use `pw_cap.ps1 -Resize` once to snap to that.

## Standard verify loop

1. **Window present?**
   ```powershell
   powershell -File scripts\wstat.ps1 -Action stat
   ```
   If missing → app not running. If minimized → `-Action restore`.

2. **Act** (prefer real click for focus/keyboard):
   ```powershell
   powershell -File scripts\click.ps1 -RelX 76 -RelY 170
   # or synthetic (client coords):
   powershell -File scripts\msg.ps1 -ClickX 100 -ClickY 200
   # hover:
   powershell -File scripts\wstat.ps1 -Action move 500 300
   ```

3. **Wait** 150–400ms for a GPUI frame.

4. **Capture**:
   ```powershell
   powershell -File scripts\pw_cap.ps1 -OutPng $env:TEMP\step1.png
   ```
   If the PNG looks stale: jiggle is already in `pw_cap`; still wrong → `cap.ps1`; still wrong → restart the app.

5. **Read the PNG** (vision) and compare to mock: layout, spacing, colors, labels, focus borders/carets, overlays (dropdown under bar vs center modal), toasts.

6. **Log** action args → capture path → pass/fail.

## Focus / keyboard (GPUI)

GPUI key events dispatch only from the **focused** element. Without `FocusHandle` + `track_focus` + `window.focus(...)`, root `on_key_down` may never run when focus is `None`.

Verify only with **physical** input:

1. `click.ps1` on the field → `pw_cap.ps1` → expect caret / primary border.
2. Type with `SendKeys` / `SendInput` (foreground window), not PostMessage → capture → expect text.
3. Shortcuts (e.g. Ctrl+F): ensure foreground, `SendKeys ^f` → capture → focus moved + correct overlay position.

## Capture methods

| Method | When |
|--------|------|
| `pw_cap.ps1` | Default after every action |
| `cap.ps1` | Stale PrintWindow, or need real screen pixels / other windows |
| `shot_app.ps1` | First launch / clean state (starts and stops the app) |

## Build / run hygiene

- `cargo build` fails with **Access denied** if the exe is running → stop the process first.
- Restore window before UI work if another process minimized/resized it: `wstat.ps1 -Action restore`.
- Prefer filesystem / server logs / app state JSON when synthetic input is ignored (input wedge); restart the app before re-verifying UI.

## Hard rules

- Never leave the app running across a rebuild.
- Never trust code-only claims for UI — always capture and read the image.
- Update the project’s living progress file after each verified step.
- Folderwise git commits only after visual verification.
