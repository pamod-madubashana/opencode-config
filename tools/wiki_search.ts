import { tool } from "@opencode-ai/plugin"
import path from "path"
import { existsSync, readdirSync, readFileSync } from "fs"

interface Frontmatter {
  type?: string
  title?: string
  description?: string
  tags?: string[]
  status?: string
  stale_after?: string
}

function parseFrontmatter(text: string): Frontmatter {
  const match = text.match(/^---\n([\s\S]*?)\n---\n?/)
  if (!match) return {}
  const result: Record<string, unknown> = {}
  const lines = match[1].split("\n")
  let currentKey: string | null = null
  let currentList: string[] | null = null
  for (const raw of lines) {
    const line = raw.trimEnd()
    if (!line.trim() || line.trim().startsWith("#")) continue
    const listItem = line.match(/^\s*-\s+(.*)$/)
    if (listItem && currentList) {
      const item = listItem[1].trim()
      const quoted = item.match(/^["'](.*)["']$/)
      currentList.push(quoted ? quoted[1] : item.replace(/,\s*$/, ""))
      continue
    }
    const keyMatch = line.match(/^([a-zA-Z_][a-zA-Z0-9_]*):\s*(.*)$/)
    if (keyMatch) {
      const key = keyMatch[1]
      const value = keyMatch[2].trim()
      if (value === "" && line.endsWith(":")) {
        currentKey = key
        currentList = []
        result[key] = currentList
      } else if (value.startsWith("[") && value.endsWith("]")) {
        // Inline list form: [a, b, c]
        const inner = value.slice(1, -1).trim()
        result[key] = inner.length === 0 ? [] : inner.split(",").map((s) => {
          const t = s.trim()
          const quoted = t.match(/^["'](.*)["']$/)
          return quoted ? quoted[1] : t
        })
        currentKey = key
        currentList = null
      } else if (value === "[]") {
        result[key] = []
        currentKey = key
        currentList = null
      } else {
        currentKey = key
        currentList = null
        const quoted = value.match(/^["'](.*)["']$/)
        result[key] = quoted ? quoted[1] : value
      }
    }
  }
  return result as Frontmatter
}

export default tool({
  description:
    "Search the project wiki (OKF v0.2 bundle) by keyword. Matches frontmatter title, description, type, and tags in addition to body text. Returns matching concept paths with title, description, and excerpt.",
  args: {
    query: tool.schema.string().describe("Keyword or topic to search for in the wiki"),
  },
  async execute(args, context) {
    const worktree = context.worktree || "."
    const wikiDir = path.join(worktree, ".opencode", "wiki")

    if (!existsSync(wikiDir)) {
      return "No wiki found at .opencode/wiki/ in this project."
    }

    const needle = args.query.toLowerCase()
    const results: string[] = []

    function searchDir(dir: string) {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const fullPath = path.join(dir, entry.name)
        if (entry.isDirectory()) {
          searchDir(fullPath)
          continue
        }
        if (!entry.name.endsWith(".md") || entry.name === "WIKI_SCHEMA.md") continue
        let content: string
        try {
          content = readFileSync(fullPath, "utf-8")
        } catch {
          continue
        }
        const fm = parseFrontmatter(content)
        const title = (fm.title ?? "").toString()
        const description = (fm.description ?? "").toString()
        const type = (fm.type ?? "").toString()
        const tags = (fm.tags ?? []).map((t) => t.toString().toLowerCase())
        const body = content.replace(/^---\n[\s\S]*?\n---\n?/, "")

        const searchable = [
          title,
          description,
          type,
          tags.join(" "),
          body,
          entry.name,
        ]
          .join("\n")
          .toLowerCase()

        if (!searchable.includes(needle)) continue

        const relPath = path.relative(worktree, fullPath)
        const lines = body.split("\n")
        const matchingLines: string[] = []
        for (let i = 0; i < lines.length && matchingLines.length < 3; i++) {
          if (lines[i].toLowerCase().includes(needle)) {
            matchingLines.push(`  L${i + 1}: ${lines[i].trim()}`)
          }
        }

        const header = [
          relPath,
          title ? `  title: ${title}` : null,
          type ? `  type: ${type}` : null,
          description ? `  description: ${description}` : null,
          tags.length ? `  tags: ${tags.join(", ")}` : null,
          matchingLines.length ? matchingLines.join("\n") : null,
        ]
          .filter(Boolean)
          .join("\n")

        results.push(header)
      }
    }

    searchDir(wikiDir)

    if (results.length === 0) {
      return `No wiki pages found matching "${args.query}".`
    }

    const limited = results.slice(0, 5)
    return `Found ${results.length} matching wiki page(s):\n\n${limited.join("\n\n")}`
  },
})