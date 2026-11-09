# Design
Goal: build a high-end, visually striking, fast landing page for Bơi Hia in `/site`. Follow `../README.md` first (stop control, rules). **Run only when the owner starts you by hand. Max 3 runs for v1: count them in comments on the Factory control issue (`[factory:design] run n/3`); stop at 3.**

## Scope
- Only create or edit files under `/site`. Never touch the app (`index.html`, `sw.js`, `config.js`, `manifest.json`), `schema.sql`, `.factory/`, `.github/` or `scripts/`.
- Plain static HTML, CSS and a little vanilla JS. No framework, no build step, no external fonts, scripts or CDNs. The page must not call Supabase or any API.
- Branch `claude/design-<slug>`, open a PR titled `[factory:design] ...`. Netlify posts a deploy preview link on the PR; put it in the PR description for the owner. **Never merge.**

## Look (match the app)
- Language: Vietnamese. Tone: friendly, playful, for a small group of swim friends. Name: Bơi Hia.
- Palette tokens: bg `#06142b`, bg2 `#0b2347`, card `#0f2d57`, line `#1b4373`, text `#eaf6ff`, muted `#8fb0cf`, aqua `#2be4d6`, blue `#2f8bff`. Follow `prefers-color-scheme` (light: bg `#eaf6ff`, card `#fff`, text `#06223f`).
- Deep navy to aqua gradients, large rounded cards (20px radius), a slow moving wave, an 8px spacing grid, one primary button per section.
- Mobile-first. System font stack. Big, confident type scale; generous whitespace; strong visual hierarchy.

## Page
1. Hero: name, one-line promise, phone-frame mock of the app built from CSS (no images needed), primary button **"Tham gia hội"** -> `https://boihia.netlify.app`.
2. Three feature cards: lịch bơi và RSVP, vote đi uống bia, số điện thoại + PIN (không cần tài khoản).
3. How it works in 3 steps.
4. Beer vote highlight (the fun part).
5. Short FAQ. Footer with a small note: dự án học tập, không thương mại.

## Quality bar (check before opening the PR)
- Contrast WCAG AA, visible focus states, semantic HTML, `alt` text, `lang="vi"`, correct viewport meta.
- Respect `prefers-reduced-motion` (turn off the wave and animations).
- Weight budget: whole page under 300 KB, no layout shift, works with JS disabled.
- Test at 375px and 1280px widths. State in the PR what you checked and what you could not check (for example no real device).
- No secrets, no personal data. The admin phone number must not appear.
