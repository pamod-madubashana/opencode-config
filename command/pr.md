---
description: Open a GitHub PR and a GitLab MR, merge both, and sync local — dual-platform flow.
agent: build
---

Do NOT just confirm this workflow — EXECUTE every step now in order. Never reply with only "Confirmed — same workflow locked in".

Extra instructions from user: $ARGUMENTS
Base is $1, default main when empty. New branch is $2, optional; derive feat/<slug> from changes when empty.

## Step 1 — Status

Run `git status --short`. If not a git repo, stop. Show `git diff --stat`.

## Step 2 — Detect remotes

Run `git remote -v`. Identify remotes by hostname, not by remote name:
- host contains `github.com` → GitHub remote
- host contains `gitlab` → GitLab remote

Both must exist. If either is missing, STOP and name the missing remote — this flow always targets both platforms.

## Step 3 — New branch + commit

If already on a feature branch (not base) with commits ahead, reuse it. Otherwise create new branch via `git checkout -b $2` (or derived feat/<slug> name). Then `git add -A` (skip incidental Cargo.lock churn, flag it). Commit with conventional message feat:/fix:/chore: imperative, one concern per commit.

## Step 4 — Push to both remotes

```
git push -u <github-remote> <branch>
git push -u <gitlab-remote> <branch>
```

## Step 5 — One title + description for both platforms

Message parity is mandatory: the PR and MR share the exact same conventional title `<T>` and body `<D>`.

Templates, in priority order:
1. GitHub: `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE/` — follow its structure if present.
2. GitLab: `.gitlab/merge_request_templates/*.md` — use if no GitHub template.
3. Neither: freeform conventional description.

Build `<T>` and `<D>` once; both platforms get them verbatim.

## Step 6 — Create GitHub PR first

Create first because the shared squash-commit suffix needs the PR number `#N`:

```
gh pr create --repo <owner/repo-from-github-remote> --base <base> --title "<T>" --body "<D>"
```

Parse the PR number `N` and URL from the output. Return the PR URL. If `gh` is missing, say so and stop.

## Step 7 — Create GitLab MR with identical title + body

```
glab mr create --repo <group/project-from-gitlab-remote> --source-branch <branch> --target-branch <base> --title "<T>" --description "<D>" --yes
```

Pass `--repo` explicitly — with two remotes, glab/gh can pick the wrong one. Parse the MR URL and IID. Return the MR URL.

## Step 8 — Merge GitLab first

Merge GitLab before GitHub so GitHub's local-branch cleanup runs last:

```
glab mr merge <iid> --squash --squash-message "<T> (#<N>)\n\n<D>" --remove-source-branch --yes --auto-merge=false
```

The suffix is the GitHub PR number `(#N)` — per user rule, the squash-commit message is identical on both platforms. If the merge is blocked (pipeline/approvals), report it with the exact retry command and continue to Step 9.

## Step 9 — Merge GitHub

```
gh pr merge <N> --squash --subject "<T> (#<N>)" --body "<D>" --delete-branch
```

Confirm `merged: true` and note the merge SHA. `--delete-branch` removes the GitHub remote branch and the local branch. If this merge fails, report it, skip Step 10 cleanup, keep the branch, and give the retry command.

## Step 10 — Sync local

- `git checkout <base>` (likely already there after `--delete-branch`).
- `git pull <github-remote> <base>` — fast-forward to the merge commit.
- `git branch -d <branch>` — skip gracefully if already deleted.
- Report: PR URL, MR URL, both merge SHAs, the identical squash-commit title, synced base, deleted branches.

## Rules

- `/pr` implies full-flow consent for push, merge, and delete; never do these without an explicit user request — anything less does not.
- One concern per commit; imperative mood; no unrelated files (e.g. leave incidental Cargo.lock churn uncommitted and flag it).
- Squash-commit message format is identical on both platforms: `<T> (#<N>)` with body `<D>` — GitHub's `(#N)` suffix kept on both, per user.
