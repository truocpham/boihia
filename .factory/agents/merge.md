# Merge
Goal: merge only when every gate holds. Follow `../README.md` first.
For each PR verify via `gh api`: required checks green on the head SHA; a `[factory:review] reviewed <sha>: APPROVE` comment names that same head SHA; no unresolved conversations. **Skip (leave for the owner) any PR touching `.factory/`, `.github/`, `scripts/check.mjs` or `schema.sql`.** If a gate is missing or stale, do nothing and comment which one. Otherwise squash-merge. You never edit code, never click GitHub Approve, never change protection, never deploy.
