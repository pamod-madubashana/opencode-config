---
name: release-workflow
description: "Create a 3-step release.yml: verify+bump version, build artifacts, and create a GitHub Release with notes. Triggers on: release.yml, create release, bump version, GitHub workflow, version bump, changelog."
---

# 3-Step Release Workflow

Create a `.github/workflows/release.yml` that: (1) validates and bumps version, (2) builds artifacts, (3) creates a GitHub Release with auto-generated notes.

## What You Must Do When Invoked

1. **Identify the version source** — read the project to find where version is defined (`package.json`, `Cargo.toml`, `tauri.conf.json`, etc.)
2. **Identify the build command and artifact path** — what command produces the release binaries, and where they land
3. **Fill in the template below** with project-specific values

---

## Step 1 — Verify + Bump Version and Commit

*Recommended approach: validate + bump-version jobs*

The workflow starts with a `workflow_dispatch` input for the version string. A validate job normalizes it to semver, then a bump job updates all version files and commits.

```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version number (e.g., 1.0.0 or v1.0.0)'
        required: true
        type: string

permissions:
  contents: write
  pull-requests: read

jobs:
  validate:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.normalize.outputs.version }}
    steps:
      - name: Normalize version
        id: normalize
        run: |
          VERSION="${{ inputs.version }}"
          VERSION="${VERSION#v}"
          if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Error: Version must be in semver format"
            exit 1
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT

  bump-version:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Update version files
        run: |
          VERSION="${{ needs.validate.outputs.version }}"
          # TODO: Update all version files here (package.json, Cargo.toml, etc.)
          echo "$VERSION" > VERSION
      - name: Commit version bump
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add -A
          git diff --cached --quiet || git commit -m "chore(release): v${{ needs.validate.outputs.version }}"
          git push origin HEAD
          echo "sha=$(git rev-parse HEAD)" >> $GITHUB_OUTPUT
    outputs:
      sha: ${{ steps.commit.outputs.sha }}
```

**Placeholder to fill:** The `Update version files` step — list every file containing the version string and the command to update it.

---

## Step 2 — Build Artifacts

*Recommended approach: build job with matrix support for multi-platform builds*

A build job checks out the bumped commit, runs the build, and uploads artifacts. Use a matrix for multi-platform builds.

```yaml
  build:
    needs: [validate, bump-version]
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.bump-version.outputs.sha }}
      # TODO: Add setup steps (Node.js, Rust, etc.)
      - name: Build
        run: |
          # TODO: Replace with your build command
          npm install && npm run build
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-assets-${{ matrix.os }}
          path: |
            # TODO: Replace with your artifact glob pattern
            release/**
```

**Placeholder to fill:** Setup steps (Node/Rust/etc.), build command, and artifact path glob.

---

## Step 3 — Create GitHub Release with Notes

*Recommended approach: publish job with ncipollo/release-action*

A publish job downloads all artifacts, resolves the tag, and creates the release using `ncipollo/release-action@v1` which handles tag creation, asset upload, and release notes generation in a single step.

```yaml
  publish:
    name: Publish GitHub release
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          path: release-assets
      - name: Resolve release tag
        id: tag
        shell: bash
        run: |
          if [ -n "${{ inputs.version }}" ]; then
            tag="${{ inputs.version }}"
          else
            tag="$(node -p "require('./package.json').version")"
          fi
          echo "tag=$tag" >> "$GITHUB_OUTPUT"
      - name: Create release and upload assets
        uses: ncipollo/release-action@v1
        with:
          tag: ${{ steps.tag.outputs.tag }}
          name: Release ${{ steps.tag.outputs.tag }}
          artifacts: "release-assets/**/*"
          generateReleaseNotes: true
          allowUpdates: true
          draft: false
          prerelease: false
          token: ${{ secrets.GITHUB_TOKEN }}
```

**Why this approach over `gh release create`:** `ncipollo/release-action@v1` handles tag creation, artifact upload, and release notes generation atomically. The alternative using `gh release create --generate-notes` followed by `gh release edit` to append custom sections is fragile and requires manual body manipulation.

---

## Full Template

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version number (e.g., 1.0.0 or v1.0.0)'
        required: true
        type: string

permissions:
  contents: write
  pull-requests: read

jobs:
  validate:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.normalize.outputs.version }}
    steps:
      - name: Normalize version
        id: normalize
        run: |
          VERSION="${{ inputs.version }}"
          VERSION="${VERSION#v}"
          if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Error: Version must be in semver format"
            exit 1
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT

  bump-version:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Update version files
        run: |
          VERSION="${{ needs.validate.outputs.version }}"
          # TODO: Update all version files
          echo "$VERSION" > VERSION
      - name: Commit version bump
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add -A
          git diff --cached --quiet || git commit -m "chore(release): v${{ needs.validate.outputs.version }}"
          git push origin HEAD
          echo "sha=$(git rev-parse HEAD)" >> $GITHUB_OUTPUT
    outputs:
      sha: ${{ steps.commit.outputs.sha }}

  build:
    needs: [validate, bump-version]
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.bump-version.outputs.sha }}
      # TODO: Add setup steps (Node.js, Rust, etc.)
      - name: Build
        run: |
          # TODO: Replace with your build command
          npm install && npm run build
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-assets-${{ matrix.os }}
          path: |
            # TODO: Replace with your artifact glob
            release/**

  publish:
    name: Publish GitHub release
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          path: release-assets
      - name: Resolve release tag
        id: tag
        shell: bash
        run: |
          if [ -n "${{ inputs.version }}" ]; then
            tag="${{ inputs.version }}"
          else
            tag="$(node -p "require('./package.json').version")"
          fi
          echo "tag=$tag" >> "$GITHUB_OUTPUT"
      - name: Create release and upload assets
        uses: ncipollo/release-action@v1
        with:
          tag: ${{ steps.tag.outputs.tag }}
          name: Release ${{ steps.tag.outputs.tag }}
          artifacts: "release-assets/**/*"
          generateReleaseNotes: true
          allowUpdates: true
          draft: false
          prerelease: false
          token: ${{ secrets.GITHUB_TOKEN }}
```

---

## Permissions Required

- `contents: write` — needed to create tags and GitHub Releases
- `pull-requests: read` — needed for checkout and status checks

---

## Verification Checklist

After creating the workflow:

1. **Trigger the workflow** — `gh workflow run Release -f version=1.0.0`
2. **Verify the tag** — `git tag -l` should show `v1.0.0` (or your input tag)
3. **Verify the release** — `gh release view v1.0.0` should show the release with assets and generated notes
4. **Verify artifacts** — `gh release view v1.0.0 --json assets` should list uploaded files

---

## Notes on the Updater Skill

If the project also needs a self-updater (checking GitHub Releases for updates), see the `updater` skill at `~/.config/opencode/skills/updater/SKILL.md`. That skill covers the in-app updater logic; this skill covers the CI/CD release pipeline.
