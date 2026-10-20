---
name: wiki-lint
description: Health-check the project wiki for OKF v0.2 conformance — missing frontmatter, missing `type:`, malformed `index.md`/`log.md`, stale pages past `stale_after`, broken cross-references, and coverage gaps.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: project-wiki
---

# Wiki Lint

## When to Use
- "Check the wiki health"
- "Lint the wiki"
- "Are there stale wiki pages?"
- After major refactors
- Monthly maintenance

## Workflow
1. Invoke the wiki-curator agent with the lint operation.
2. The curator runs the conformance checklist from `WIKI_SCHEMA.md`:
   - Parseable YAML frontmatter on every non-reserved `.md` file
   - Non-empty `type:` on every concept
   - `index.md` and `log.md` follow their structure when present
   - `sources[].id` is unique per concept
   - Markdown footnote labels match a `sources[].id`
   - `stale_after` is an ISO date when present
   - Cross-references resolve or are flagged as future-writes
3. The curator marks stale pages (`⚠️ STALE — past stale_after (<date>)` or `⚠️ STALE — last verified <date>`) at the top of the body.
4. Report findings categorized by severity (critical / warning / note).
5. Ask the user which issues to fix automatically vs flag for manual review.

## Notes
- OKF v0.2 is permissive: missing optional fields, unknown types, unknown
  extra frontmatter keys, and broken cross-links are warnings, not failures.
- A missing `type:` field is the only conformance failure that prevents a
  bundle from being consumable.
- Trust tiers are advisory. A wiki without `verified:` entries is still
  consumable; consumers just classify such pages as "unverified".