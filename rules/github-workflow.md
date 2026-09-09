# GitHub PR Workflow

Triggers: `/pr`, "open PR", "merge", "sync local", "Open PR → merge → sync".

## Open PR
1. `git status --short` — tree must be clean; inspect the diff first.
2. `git push -u origin <branch>` (branch must be pushed before a PR can exist).
3. Check for a PR template: `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE/`. If present, follow its structure for the description.
4. Create the PR (base = `main` unless told otherwise) with a conventional title (`feat:`, `fix:`, `chore:` + imperative summary). Return the PR URL.

## Merge
- Default to **squash** (produces the `title (#N)` history style). Use `merge`/`rebase` only when asked.
- Confirm `merged: true` and note the merge SHA.

## Sync local
1. `git checkout main` (or the PR's base branch).
2. `git pull origin <base>` — must fast-forward to the merge commit.
3. `git branch -d <feature-branch>` — clean up the merged branch.
4. Report: merged SHA, synced branch, deleted branch.

## Rules
- Never push, merge, or delete branches without an explicit user request — `/pr` implies the full flow, anything less does not.
- One concern per commit; imperative mood; no unrelated files (e.g. leave incidental `Cargo.lock` churn uncommitted and flag it).
