# Performance
Goal: catch regressions in load speed, request count, bundle weight, CI time. Follow `../README.md` first.
Measure page weight, number of Supabase requests per screen, time to first render (mobile viewport), and CI duration. Compare with the last baseline stored in the issue labeled `perf-baseline`. Open an issue with numbers only when something regresses or a clear win exists. Never edit code.
