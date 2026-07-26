# Agent Journal - Airlock

## Issues
- jacSpawn dict arg type error: fixed by assigning dict to `any` typed variable first before passing to jacSpawn
- urlopen with-statement type error: fixed by not using context manager, calling urlopen directly
- list type error in demo_agent: fixed with explicit `list[any]` cast

## Learnings
- jacSpawn second arg must be typed `any` to avoid dict type mismatch
- urlopen returns `any` in Jac type system; avoid `with` statement, call directly
- `by llm()` functions work without explicit `glob llm` - jac.toml byllm config is used
- Risk enum with `str` base: members ARE the string values, no `.value` needed
- FOLLOWS edge needs endpoint types declared for proper type inference
- Template had empty `example_files[]` so no file cleanup needed

## Firecrawl integration (added for "Best Use of Firecrawl" track)
- New concept: `web_fetch` actions are not trusted from the agent's self-report alone. `scrape_url()` in `main.jac` calls Firecrawl's `POST /v2/scrape` (Bearer auth, `{"url", "formats": ["markdown"]}`, response at `data.markdown`) to independently re-fetch the real page.
- Action node gained `url`, `verified`, `claimed_risk`, `verified_risk`, `scraped_excerpt` fields; `log_action` now runs a baseline `classify_risk` (self-report) plus, for `web_fetch`, a second `classify_scraped_risk` pass over the real scraped content, escalating `risk` to the more severe of the two via `risk_severity()`.
- Requires `FIRECRAWL_API_KEY` env var (not stored in jac.toml or committed anywhere — read via `os.environ.get(...) as str`, same `.get(...) as <type>` cast pattern used elsewhere for Jac's type checker).
- Demo step 6 in `demo_agent.jac` points at the Wikipedia SQL Injection article — a real, stable, public page that legitimately contains a `DROP TABLE` example, giving a genuine claimed-vs-verified risk mismatch without fabricating anything.
- ActionCard.jac shows a "Verified via Firecrawl" badge and, when claimed/verified risk diverge, a comparison callout with the scraped excerpt.
- Not yet run end-to-end locally (no `jac` CLI available in this environment to `jac check`/`jac start --dev`) — verify before demoing.

## Last Action
Build complete. App renders at preview URL with:
- Airlock dashboard with stats bar (safe/review/dangerous counts)
- Empty state with `jac run demo_agent.jac` instruction
- ActionCard component with color-coded risk badges and approve/override buttons
- Audit Report button that calls get_audit_summary() via byLLM
- demo_agent.jac fires 5 realistic actions (2 safe, 2 review, 1 dangerous DROP TABLE)
- All walkers: log_action, audit_report, approve registered as REST endpoints
- byLLM: classify_risk, explain_action, synthesize_audit
