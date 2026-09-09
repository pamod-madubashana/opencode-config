---
description: Open a PR, merge it, and sync local — the full GitHub workflow.
agent: build
---

Do NOT just confirm this workflow — EXECUTE every step now in order. Never reply with only "Confirmed — same workflow locked in".

Extra instructions from user: $ARGUMENTS
Base is $1, default main when empty. New branch is $2, optional; derive feat/<slug> from changes when empty.

## Step 1 — Status

Run `git status --short`. If not a git repo, stop. Show `git diff --stat`.

## Step 2 — New branch + commit

If already on a feature branch (not base) with commits ahead, reuse it. Otherwise create new branch via `git checkout -b $2` (or derived feat/<slug> name). Then `git add -A` (skip incidental Cargo.lock churn, flag it). Commit with conventional message feat:/fix:/chore: imperative, one concern per commit.

## Step 3 — Push

`git push -u origin <new-or-current-branch>`.

## Step 4 — PR template

Check `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE/`. If present, follow its structure for the PR description.

## Step 5 — Create PR

Create via `gh pr create --base <base>` (base is $1, default main). Conventional title. Return the PR URL. If `gh` is missing, say so.

## Step 6 — Merge

`gh pr merge --squash`. Confirm `merged: true` and note the merge SHA.

## Step 7 — Sync local

- `git checkout <base>`
- `git pull origin <base>` — fast-forward to the merge commit.
- `git branch -d <feature-branch>` — clean up.
- Report: merged SHA, synced branch, deleted branch.

## Rules

- `/pr` implies full-flow consent for push, merge, and delete; never do these without an explicit user request — anything less does not.
- One concern per commit; imperative mood; no unrelated files (e.g. leave incidental Cargo.lock churn uncommitted and flag it).
