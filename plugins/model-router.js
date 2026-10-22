
// Model router: picks the best currently-available model per agent tier at
// startup, so subagents never pin a model ID that the free catalog has dropped.
// Tiers: heavy (planners/reviewers), code (pro/refactor agents), fast (explore/research).
// Ranking: tool-call support required; deprecated excluded; free-only when any free
// model qualifies (falls back to the full pool otherwise).
//
// Catalog sources, in order:
//   1. ~/.cache/opencode/models.json — synchronous, so it works inside the config hook.
//   2. client.provider.list(...)     — background refinement. The config hook runs during
//      init, when the server call can time out, so it must never gate startup.
//
// The cache holds every provider on models.dev (200+), most of which this machine
// cannot use, so ranking is scoped to providers the config actually references
// (existing agent/small_model refs plus explicit `provider:` entries) — otherwise
// the router would pick an unreachable model and every call would 404.
//
// Progress is appended to <data>/opencode/log/model-router.log because plugin
// console output does not reach the main opencode log.

import { readFileSync, statSync, appendFileSync } from "node:fs"
import { homedir } from "node:os"

const AGENT_TIER = {
  plan: "heavy",
  coordinator: "heavy",
  reviewer: "heavy",
  "python-reviewer": "heavy",
  "ops-reviewer": "heavy",
  "swarm-planner": "heavy",
  "python-pro": "code",
  "rust-pro": "code",
  "go-pro": "code",
  "typescript-pro": "code",
  refactorer: "code",
  "ops-specialist": "code",
  explore: "fast",
  archaeologist: "fast",
  "swarm-researcher": "fast",
  "swarm-worker": "fast",
  "readme-maintainer": "fast",
  "wiki-curator": "fast",
}

const DEFAULT_TIER = "code"
const CATALOG_TIMEOUT_MS = 5_000

const cachePath = () =>
  process.env.XDG_CACHE_HOME
    ? `${process.env.XDG_CACHE_HOME}/opencode/models.json`
    : `${homedir()}/.cache/opencode/models.json`

const logPath = () =>
  process.env.XDG_DATA_HOME
    ? `${process.env.XDG_DATA_HOME}/opencode/log/model-router.log`
    : `${homedir()}/.local/share/opencode/log/model-router.log`

const log = (msg) => {
  console.warn(`[model-router] ${msg}`)
  try {
    appendFileSync(logPath(), `[${new Date().toISOString()}] ${msg}\n`)
  } catch {
    // logging must never break plugin load
  }
}

const isFree = (m) => (m.cost?.input ?? 1) === 0 && (m.cost?.output ?? 1) === 0

const withTimeout = (promise) => {
  let timeout
  const timedOut = new Promise((_, reject) => {
    timeout = setTimeout(
      () => reject(new Error(`provider catalog request timed out after ${CATALOG_TIMEOUT_MS}ms`)),
      CATALOG_TIMEOUT_MS,
    )
  })

  return Promise.race([promise, timedOut]).finally(() => clearTimeout(timeout))
}

const score = (m, tier) => {
  const ctx = Math.min(m.limit?.context ?? 0, 400_000) / 400_000
  const out = Math.min(m.limit?.output ?? 0, 32_000) / 32_000
  const free = isFree(m) ? 1 : 0
  const reason = m.reasoning ? 1 : 0
  const flashish = /flash|lightning|mini|small|nano/i.test(m.id) ? 1 : 0

  if (tier === "heavy") return reason * 35 + ctx * 30 + out * 20 + free * 15
  if (tier === "code") return ctx * 35 + out * 25 + reason * 20 + free * 20
  return flashish * 30 + free * 30 + ctx * 15 + out * 10 + (reason ? 5 : 0)
}

const rank = (models, preferredProvider, tier) => {
  const eligible = models.filter((m) => m.tool_call !== false && m.status !== "deprecated")
  const free = eligible.filter(isFree)
  const pool = free.length ? free : eligible

  return pool
    .map((m) => ({
      ref: `${m.providerID}/${m.id}`,
      score: score(m, tier) + (m.providerID === preferredProvider ? 5 : 0),
    }))
    .sort((a, b) => b.score - a.score || a.ref.localeCompare(b.ref))
}

const toCatalog = (providers) => {
  const models = []
  const available = new Set()

  for (const p of providers) {
    for (const [id, m] of Object.entries(p.models ?? {})) {
      models.push({ ...m, id, providerID: p.id })
      if (m.tool_call !== false && m.status !== "deprecated") available.add(`${p.id}/${id}`)
    }
  }

  const preferred = providers.find((p) => p.id === "opencode")?.id ?? providers[0]?.id
  return {
    available,
    count: models.length,
    picks: {
      heavy: rank(models, preferred, "heavy")[0]?.ref,
      code: rank(models, preferred, "code")[0]?.ref,
      fast: rank(models, preferred, "fast")[0]?.ref,
    },
  }
}

const describe = (p) => `heavy=${p.heavy} code=${p.code} fast=${p.fast}`

export default async ({ client, directory }) => {
  let picks = { heavy: undefined, code: undefined, fast: undefined }
  let available = new Set()
  let usable = null

  // Providers this install can actually call: those already referenced by the
  // config (agent models, model/small_model) plus explicit `provider:` entries.
  const referencedProviders = (cfg) => {
    const set = new Set()
    const add = (ref) => {
      if (typeof ref !== "string") return
      const i = ref.indexOf("/")
      if (i > 0) set.add(ref.slice(0, i))
    }

    add(cfg?.model)
    add(cfg?.small_model)
    for (const entry of Object.values(cfg?.agent ?? {})) {
      if (entry && typeof entry === "object") add(entry.model)
    }
    for (const key of Object.keys(cfg?.provider ?? {})) set.add(key)

    if (!set.size) set.add("opencode") // built-in free provider needs no credentials
    return set
  }

  const apply = (cfg, providers, source) => {
    if (!usable) usable = referencedProviders(cfg)

    const inScope = providers.filter((p) => usable.has(p.id))
    if (!inScope.length) {
      log(
        `${source}: none of the ${providers.length} catalog providers are usable (scope=[${[...usable].join(",")}]) — leaving models untouched`,
      )
      return
    }

    const next = toCatalog(inScope)
    picks = next.picks
    available = next.available

    const agents = cfg?.agent
    if (!agents || typeof agents !== "object") {
      log(
        `${source}: catalog=${next.count} providers=${inScope.length}/${providers.length} ${describe(picks)} — no cfg.agent map, nothing to route`,
      )
      return
    }

    let changed = 0
    for (const [name, entry] of Object.entries(agents)) {
      if (!entry || typeof entry !== "object") continue
      const tier = AGENT_TIER[name] ?? DEFAULT_TIER
      const ref = picks[tier]
      if (!ref || entry.model === ref) continue
      entry.model = ref
      changed++
      log(`${name} -> ${ref} (tier=${tier})`)
    }

    if (typeof cfg?.small_model === "string" && !available.has(cfg.small_model) && picks.fast) {
      log(`small_model ${cfg.small_model} missing/deprecated -> ${picks.fast}`)
      cfg.small_model = picks.fast
    }

    log(
      `${source}: catalog=${next.count} providers=${inScope.length}/${providers.length} scope=[${[...usable].join(",")}] ${describe(picks)} agents_changed=${changed}`,
    )
  }

  const cacheProviders = () => {
    const path = cachePath()
    const json = JSON.parse(readFileSync(path, "utf8"))
    const providers = Object.entries(json).map(([id, p]) => ({ id, models: p?.models ?? {} }))
    if (!providers.length) throw new Error("cache catalog empty")

    let mtime = "unknown"
    try {
      mtime = statSync(path).mtime.toISOString()
    } catch {
      // stat is informational only
    }
    return { providers, mtime }
  }

  const liveProviders = async () => {
    const res = await withTimeout(client.provider.list({ query: { directory } }))
    const payload = res?.data ?? res
    const providers = payload?.all ?? []
    if (!providers.length) throw new Error("provider list returned no providers")
    return providers
  }

  return {
    config: async (cfg) => {
      try {
        const { providers, mtime } = cacheProviders()
        apply(cfg, providers, `cache(${mtime})`)
      } catch (e) {
        log(`cache read failed: ${e}`)
      }

      // Best-effort live refinement. Never awaited: the config hook runs during
      // startup and a pending server call here blocks (or times out) init.
      liveProviders()
        .then((providers) => apply(cfg, providers, "live"))
        .catch((e) => log(`live refresh failed: ${e}`))
    },
  }
}
