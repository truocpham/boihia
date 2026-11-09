# Merge
Goal: merge only when every gate holds. Follow `../README.md` first.
For each PR verify via `gh api`: required checks green on the head SHA; `[factory:review] ... APPROVE` names that same SHA; a human approval (from `@truocpham`, not a bot, not you) exists on that same SHA; no unresolved conversations. If any is missing or stale, do nothing and comment which gate is missing. Otherwise squash-merge. You never approve, never edit code, never change protection.
