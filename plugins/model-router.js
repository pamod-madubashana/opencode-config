
// Model router: picks the best currently-available model per agent tier at
// startup, so subagents never pin a model ID that the free catalog has dropped.
// Tiers: heavy (planners/reviewers), code (pro/refactor agents), fast (explore/research).
// Ranking: tool-call support required; then reasoning, context, output, free cost.

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

const rank = (models, preferredProvider, tier) =>
  models
    .filter((m) => m.tool_call !== false && m.status !== "deprecated")
    .map((m) => ({
      ref: `${m.providerID}/${m.id}`,
      score: score(m, tier) + (m.providerID === preferredProvider ? 5 : 0),
    }))
    .sort((a, b) => b.score - a.score || a.ref.localeCompare(b.ref))

export default async ({ client, directory }) => {
  let picks = { heavy: undefined, code: undefined, fast: undefined }
  let available = new Set()

  const refresh = async () => {
    const res = await withTimeout(client.provider.list({ query: { directory } }))
    const payload = res?.data ?? res
    const providers = payload?.all ?? []

    const models = []
    available = new Set()
    for (const p of providers) {
      for (const [id, m] of Object.entries(p.models ?? {})) {
        models.push({ ...m, id, providerID: p.id })
        available.add(`${p.id}/${id}`)
      }
    }

    const preferred = providers.find((p) => p.id === "opencode")?.id ?? providers[0]?.id
    picks = {
      heavy: rank(models, preferred, "heavy")[0]?.ref,
      code: rank(models, preferred, "code")[0]?.ref,
      fast: rank(models, preferred, "fast")[0]?.ref,
    }
    console.warn(
      `[model-router] catalog=${models.length} heavy=${picks.heavy} code=${picks.code} fast=${picks.fast}`,
    )
  }

  return {
    config: async (cfg) => {
      await refresh().catch((e) => console.warn(`[model-router] refresh failed: ${e}`))

      const agents = cfg?.agent
      if (!agents || typeof agents !== "object") {
        console.warn("[model-router] no cfg.agent map found — nothing to route")
        return
      }

      for (const [name, entry] of Object.entries(agents)) {
        if (!entry || typeof entry !== "object") continue
        const tier = AGENT_TIER[name] ?? DEFAULT_TIER
        const ref = picks[tier]
        if (!ref || entry.model === ref) continue
        entry.model = ref
        console.warn(`[model-router] ${name} -> ${ref} (tier=${tier})`)
      }

      if (typeof cfg?.small_model === "string" && !available.has(cfg.small_model) && picks.fast) {
        console.warn(`[model-router] small_model ${cfg.small_model} missing -> ${picks.fast}`)
        cfg.small_model = picks.fast
      }
    },
  }
}
