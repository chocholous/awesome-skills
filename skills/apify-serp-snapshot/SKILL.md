---
name: apify-serp-snapshot
description: Take a quick snapshot of Google Search results for one or more queries — top organic results with position, title, URL, and description — for SEO monitoring, rank checks, and content research. Runs the public apify/google-search-scraper Actor with cost guardrails (1 SERP page per query, up to 10 queries batched per run; more pages only on explicit user request). Use when the user says "grab the SERP for this keyword", "snapshot Google results", "check top 10 for a query", "SERP monitoring", "what ranks for a keyword", or wants a lightweight organic-results check without a full SEO toolchain.
author: dry-run tester
author_url: https://github.com/chocholous
---

# SERP Snapshot

Grab a quick, cheap snapshot of Google organic search results for one or more queries — position, title, URL, and description per result — for SEO monitoring and rank checks.

## Prerequisites

- Apify account ([sign up](https://apify.com))
- Authentication via one of:
  - `apify login` (OAuth, if using the Apify CLI)
  - `APIFY_TOKEN` environment variable
  - Token from [Apify Console → Settings → Integrations](https://console.apify.com/settings/integrations)

## Workflow

1. **Collect queries and market.** Gather the search queries from the user. The Actor's `queries` field is a **single newline-separated string, not an array** — join multiple queries with `\n`. Country defaults to `countryCode: "us"` unless the user names a market.
2. **Build the input with cost guardrails on.** Always set `maxPagesPerQuery: 1` and batch at most 10 queries per run. Raise pages or batch size only when the user explicitly asks — the Actor is paid per scraped SERP page, so pages × queries is the cost driver (see [references/gotchas.md](references/gotchas.md)).
3. **Run the Actor** using one of the interfaces below. With the CLI, the `--json` output of a successful call carries the run under `.run` (`id`, `status`, console `url`) and the dataset ID at `.storage.defaultDatasetId`.
4. **Fetch results and deliver.** Each dataset item is one query's SERP page with an `organicResults` array. Render a per-query table of `position`, `title`, `url`, `description`, report result counts, and link the dataset/console URL. Expect roughly the top 10 organic results per page — the exact count varies (7–10 observed).

## Actor routing

| User need | Actor ID | Tier | Best for |
|-----------|----------|------|----------|
| Snapshot of Google organic results for keyword(s) | `apify/google-search-scraper` | apify | Top-10 organic results with position, title, URL, description; per-country targeting via `countryCode` |

`Tier` = `apify` (Apify-maintained, prefer) or `community` (third-party). This skill uses a single Apify-maintained Actor.

## Calling Actors — choose your interface

Skills in this repo can call Actors via any of these interfaces. Pick the one
that fits your runtime; cross-tool compatibility is your responsibility.

### Option A: Apify CLI (recommended for portability)

Works in any shell-capable agent. Three flags on every call:

```bash
apify actors call apify/google-search-scraper \
  -i '{"queries": "coffee grinder reviews", "countryCode": "us", "maxPagesPerQuery": 1}' \
  --json \
  --user-agent apify-awesome-skills/apify-serp-snapshot \
  2>/dev/null
```

| Flag | Why |
|------|-----|
| `--json` | Stable machine-readable output |
| `--user-agent` | Apify telemetry attribution |
| `2>/dev/null` | Suppress progress messages that break JSON |

Other useful commands:

```bash
# Inspect the input schema before building an input
apify actors info apify/google-search-scraper --input --json \
  --user-agent apify-awesome-skills/apify-serp-snapshot 2>/dev/null
```

```bash
# Fetch results — DATASET_ID comes from .storage.defaultDatasetId of the call output
apify datasets get-items DATASET_ID --format json \
  --user-agent apify-awesome-skills/apify-serp-snapshot 2>/dev/null
```

### Option B: Apify MCP connector

Hosted MCP server at <https://mcp.apify.com>, documented at
<https://docs.apify.com/platform/integrations/mcp>. Call the `call-actor` tool
with `actor: "apify/google-search-scraper"` and the same input JSON, then fetch
items with `get-dataset-items`.

### Option C: MCP client of your choice (e.g. `mcpc`)

Standalone CLI client. See <https://github.com/apify/mcpc>.

## Worked example (verified July 2026)

Input batching two queries in one run:

```json
{
  "queries": "coffee grinder reviews\nburr grinder vs blade grinder",
  "countryCode": "us",
  "maxPagesPerQuery": 1
}
```

Each dataset item is one query's SERP page, shaped like:

```json
{
  "searchQuery": { "term": "coffee grinder reviews" },
  "organicResults": [
    {
      "position": 1,
      "title": "Best Budget Coffee Grinders for 2026",
      "url": "https://coffeegeek.com/guides/feature-guides/best-budget-coffee-grinders-for-2026/",
      "description": "Best Bang for the Buck Timemore C5 ESP Pro. Reliable, repairable, ..."
    }
  ]
}
```

Parse the JSON and build the deliverable table from `organicResults`. Optional
one-liner to flatten all queries into TSV rows:

```bash
apify datasets get-items DATASET_ID --format json \
  --user-agent apify-awesome-skills/apify-serp-snapshot 2>/dev/null |
  jq -r '.[] | .searchQuery.term as $q | .organicResults[] | [$q, .position, .title, .url] | @tsv'
```

## Troubleshooting

- **Run `SUCCEEDED` but `organicResults` is empty** → usually an exotic or unsupported `countryCode`. Retry the same queries with `countryCode: "us"` and tell the user which market fell back.
- **Rate limiting or failing runs when many queries are sent at once** → keep batches at ≤10 queries per run and issue runs sequentially instead of in parallel.
- **Missing fields on some results** → `description` can be absent on an organic result and `resultsTotal` can be `null`; tolerate both instead of failing the render.
- For detailed cost guardrails and recovery, see [references/gotchas.md](references/gotchas.md).
