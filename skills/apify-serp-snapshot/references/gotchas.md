# Gotchas — SERP Snapshot

Cost guardrails, error recovery, and common pitfalls. The agent reads this
on demand when building inputs or when a run fails.

## Cost guardrails

Apify Actors use one of three pricing models. Before running, check the
model via `apify actors info "ACTOR_ID" --json 2>/dev/null` (look at
`pricingInfos`).

| Model | What to watch for |
|-------|-------------------|
| `FREE` | No cost — safe to run. |
| `PAY_PER_EVENT` | Cost scales with results. Estimate before running. |
| `FLAT_PRICE_PER_MONTH` | Subscription — runs are unlimited once paid. |

### This skill's Actor

`apify/google-search-scraper` is **`PAY_PER_EVENT`** with two charge events
(prices as of July 2026, FREE plan tier — paid plans are cheaper):

| Event | Price (FREE tier) | Notes |
|-------|-------------------|-------|
| `search-page-scraped` | $0.0045 per SERP page | The cost driver — charged per query × page |
| `actor-start` | $0.001 per run | Flat, once per run — favors batching queries into one run |

Measured on a real run: 1 query × 1 page = **$0.0055**; 2 queries × 1 page ≈ **$0.010**.

### Hard guardrails for this skill

- **`maxPagesPerQuery: 1` — always.** Raise it only when the user explicitly
  asks for more than the first page, and say what it multiplies the cost by.
- **≤ 10 queries per run.** For bigger keyword sets, split into sequential
  runs of at most 10 queries each.
- Batch queries into one run rather than one run per query — the `actor-start`
  fee is per run.

### Confirmation thresholds (suggested)

- Estimated cost **>$5** → warn the user.
- Estimated cost **>$20** → require explicit user confirmation before running.
- Always present cost as a **rough estimate** ("around $X"), not a guarantee.

With the defaults above, a full 10-query snapshot is ≈ $0.05 on the FREE
tier, so these thresholds only come into play when the user asks for many
pages or very large keyword sets.

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| Run `SUCCEEDED` but `organicResults` is `[]` | Exotic or unsupported `countryCode` | Retry the same queries with `countryCode: "us"`; report the fallback to the user |
| Runs failing / throttled with large query lists | Too many queries submitted at once | Batch ≤10 queries per run, run batches sequentially, back off briefly between runs |

## Actor-specific notes

### `apify/google-search-scraper`

- `queries` is a **single newline-separated string**, not an array — join
  multiple queries with `\n`.
- One dataset item per query per SERP page; each item carries
  `searchQuery.term` and an `organicResults` array (`position`, `title`,
  `url`, `description`).
- Organic result count per page varies — 7–10 observed on page one; do not
  assert exactly 10.
- `description` can be missing on individual results and `resultsTotal` can
  be `null` — tolerate both.
- CLI `apify actors call ... --json` output: run info under `.run`
  (`id`, `status`, console `url`), dataset ID at `.storage.defaultDatasetId`.

For a polished gotchas example with detailed cost tables and error-recovery flows, see [apify/agent-skills ultimate-scraper gotchas](https://github.com/apify/agent-skills/blob/main/skills/apify-ultimate-scraper/references/gotchas.md).
