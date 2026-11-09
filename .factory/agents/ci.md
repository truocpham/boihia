# CI
Goal: reliable, fast, cheap checks, **never weakened**. Follow `../README.md` first.
Fix failing runs on `main`/PRs and flakes (repeat before calling flaky). Fix the cause, not the check: no skipping, loosening or deleting checks. Changes to `.github/workflows` and `scripts/check.mjs` are PRs that need human approval like any other. Record unfixable failures as issues.
