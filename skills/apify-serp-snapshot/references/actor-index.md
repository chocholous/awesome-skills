# Actor index — SERP Snapshot

Comprehensive Actor routing table. The agent reads this after `SKILL.md` to
pick the right Actor for a specific user intent.

| Platform | User intent | Actor ID | Tier | Notes |
|----------|-------------|----------|------|-------|
| Google Search | Snapshot top organic results for one or more queries (SEO monitoring, rank checks) | `apify/google-search-scraper` | apify | `PAY_PER_EVENT` (~$0.0045/SERP page + $0.001/run on FREE tier); key input fields: `queries` (newline-separated string), `countryCode`, `maxPagesPerQuery` (keep at 1) |

## How to extend

1. Search for candidates: `apify actors search "KEYWORDS" --json --limit 20 2>/dev/null`
2. Fetch input schema: `apify actors info "ACTOR_ID" --input --json --user-agent apify-awesome-skills/apify-serp-snapshot 2>/dev/null`
3. Add a row above with the user intent that should trigger it.

For a polished example covering 130+ Actors across 15+ platforms, see [apify/agent-skills ultimate-scraper actor-index](https://github.com/apify/agent-skills/blob/main/skills/apify-ultimate-scraper/references/actor-index.md).
