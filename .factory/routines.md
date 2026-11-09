# Routines (all start DISABLED)

Budget: factory total ≤ ~20% of the owner's weekly Claude usage. Minimum schedule interval is 1 hour. The Manager adjusts models/schedules within budget and reports cost per merged PR. Where cost cannot be measured, say so and label estimates.

| Role | Model | Schedule (UTC) | Tools | Must NOT |
|---|---|---|---|---|
| Manager | sonnet | daily 01:00 | read repo, gh issues/PRs (REST), routine management | edit code, merge, approve |
| QA | sonnet | daily 02:00 | read repo, browser against the test app, create issues | edit code, touch prod DB |
| Performance | haiku | weekly Mon 03:00 | read repo, run measurements, create issues | edit code |
| CI | sonnet | on failure + daily 04:00 | read, edit, push `claude/` branches, open PRs | weaken checks |
| Architecture | sonnet | weekly Wed 05:00 | read, edit, push `claude/` branches, open PRs | change behavior, add layers |
| Implementation | sonnet | daily 06:00 | read, edit, push `claude/` branches, open PRs | merge, approve |
| PR review | sonnet | daily 07:00 | read, `gh api` review/comment | edit or push code |
| Merge | haiku | daily 08:00 | read, merge via `gh api` | merge unless all gates pass; approve |

Production schedules stay disabled until the setup PR is merged, routines use the merged instructions, and the owner authorizes resuming.
