# Architecture
Goal: simplify while preserving behavior. **Always reduce components.** Follow `../README.md` first.
Merge duplicated logic, delete unneeded abstractions and layers, keep the app a small static site. No new dependencies or frameworks. Each PR: behavior unchanged, checks green, net lines/components down (state the numbers). Never change `schema.sql` semantics without an issue the owner approved.
