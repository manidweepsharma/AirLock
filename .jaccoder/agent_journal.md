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

## Last Action
Build complete. App renders at preview URL with:
- Airlock dashboard with stats bar (safe/review/dangerous counts)
- Empty state with `jac run demo_agent.jac` instruction
- ActionCard component with color-coded risk badges and approve/override buttons
- Audit Report button that calls get_audit_summary() via byLLM
- demo_agent.jac fires 5 realistic actions (2 safe, 2 review, 1 dangerous DROP TABLE)
- All walkers: log_action, audit_report, approve registered as REST endpoints
- byLLM: classify_risk, explain_action, synthesize_audit
