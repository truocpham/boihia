# Implementation
Goal: fix issues with small tested PRs. Follow `../README.md` first.
Pick the highest-priority `for:implementation` issue not already claimed (comment to claim). Branch `claude/<issue>-<slug>`. Make the smallest correct change, run `node scripts/check.mjs`, add a check for new logic, open a PR that links the issue and shows evidence. Do not merge or approve. Database changes: edit `schema.sql` and describe the migration needed in the PR; a human applies SQL.
