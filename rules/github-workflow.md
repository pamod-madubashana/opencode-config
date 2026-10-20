# GitHub + GitLab PR/MR Workflow

Triggers: `/pr`, "open PR", "open MR", "merge", "sync local", "Open PR → merge → sync".

## Open PR (GitHub) + MR (GitLab) — always both
1. `git status --short` — tree must be clean; inspect the diff first.
2. Detect remotes by hostname from `git remote -v`: host containing `github.com` → GitHub remote; host containing `gitlab` → GitLab remote. Both must exist — stop and name the missing one otherwise.
3. `git push -u <github-remote> <branch>` and `git push -u <gitlab-remote> <branch>` (branch must be pushed to both before PR/MR can exist).
4. Templates: `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE/`; else `.gitlab/merge_request_templates/`. One description `<D>` is built and used verbatim on both platforms.
5. Create the GitHub PR first (base = `main` unless told otherwise) with a conventional title `<T>`; parse PR number `N`. Then create the GitLab MR with the identical `<T>` and `<D>`. Return both URLs.

## Merge — squash on both, identical message
- Merge GitLab first: `glab mr merge --squash --squash-message "<T> (#<N>)\n\n<D>" --remove-source-branch --yes`.
- Then GitHub: `gh pr merge --squash --subject "<T> (#<N>)" --body "<D>" --delete-branch`.
- The squash-commit message is byte-identical on both platforms — GitHub's `(#N)` suffix is kept on both, per user rule.
- Confirm `merged: true` on each and note both merge SHAs. If one platform fails, report it with a retry command; only skip local sync when the GitHub merge failed.

## Sync local
1. `git checkout main` (or the PR's base branch).
2. `git pull <github-remote> <base>` — must fast-forward to the merge commit. The GitHub remote is the sync source; GitLab `main` gets the same content/message but its own SHA.
3. `git branch -d <feature-branch>` — clean up the merged branch (skip if GitHub's `--delete-branch` already removed it).
4. Report: PR URL, MR URL, both merge SHAs, synced branch, deleted branch.

## Rules
- Never push, merge, or delete branches without an explicit user request — `/pr` implies the full flow, anything less does not.
- One concern per commit; imperative mood; no unrelated files (e.g. leave incidental `Cargo.lock` churn uncommitted and flag it).
