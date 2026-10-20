---
name: wiki-ingest
description: Ingest a source into the project wiki as OKF v0.2 markdown. Point at a file, PR, or doc and the wiki-curator extracts knowledge, writes YAML frontmatter, and updates relevant concept pages.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: project-wiki
---

# Wiki Ingest

## When to Use
- "Add this to the wiki"
- "Ingest this PR/file/doc into the wiki"
- "Update the wiki with these changes"
- "What did this PR change?" (ingest + query)

## Workflow
1. Identify the source to ingest (user provides file path, PR number, or topic).
2. If `.opencode/wiki/index.md` doesn't exist, ask: "No initialized wiki found. Bootstrap one by scanning the project?"
3. Invoke the wiki-curator agent with the ingest operation.
4. The curator writes OKF v0.2 concepts: required `type:` frontmatter, recommended `title:` and `description:`, optional `sources:`, `generated:`, `verified:`, `status:`, `stale_after:`.
5. The curator updates `index.md` (so `description:` from each concept appears in the listing) and appends to `log.md`.
6. Report which pages were created or updated, and which frontmatter fields changed.

## Bootstrap (First Run)

If no initialized wiki exists (there is no `.opencode/wiki/index.md`), the wiki-curator will:
1. Scan the project structure, README, AGENTS.md, and key entrypoints.
2. Pick a directory layout (e.g. `entities/`, `concepts/`, `architecture/`, `references/`).
3. Create a concept per major module with `type:`, `title:`, `description:`, and `generated:` frontmatter.
4. Initialize `index.md` with section headings and `description`-driven bullets.
5. Add a `**Initialization**` entry to `log.md`.
6. Copy `WIKI_SCHEMA.md` into the bundle root if it isn't there yet.

## Notes
- Every concept gets `generated: { by: wiki-curator/<model>, at: <ISO 8601> }` so the trust tier is derivable.
- Source citations use markdown footnotes keyed to `sources[].id`, not positional indices.
- Pages past their `stale_after` are flagged with `⚠️ STALE — past stale_after (<date>)` at the top.