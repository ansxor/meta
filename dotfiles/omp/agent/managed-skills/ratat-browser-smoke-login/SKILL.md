---
name: ratat-browser-smoke-login
description: "Sign in to the ratat frontend as a seeded testnet user in the headless browser to smoke-test authed UI flows (favourite/boost, follows, uploads)"
---

# Smoke-testing authed ratat UI in the headless browser

Prereq: dev stack up — `bun run infra:up && bun run db:migrate && bun run dev:seed`, then hub-start:
- appview: `bun run --cwd apps/xrpc-server dev` (ready: port 3010)
- consumer: `bun run dev:consumer` (ready log: `subscrib`)
- frontend: `bun run --cwd apps/frontend dev` (ready: port 3000 + log `Ready in`)

Seeded accounts: `alice.test` (clean, no content) / `bob.test` / `carol.test` / `dana.test`, passwords `<name>-pass-123`. Artwork URIs: `psql -h localhost -p 5433 -U ratat -d ratat` (password `ratat`), table `artwork_index`.

## OAuth sign-in flow (all steps needed; each has a gotcha)
1. Open `http://localhost:3000/`. The **Sign In button opens a `prompt()` dialog** for the handle — clicking without a handler hangs the run 30s and can kill the tab. Register first:
   `page.once('dialog', d => { void d.accept('alice.test'); });` then click Sign In with `page.waitForNavigation()` started BEFORE the click.
2. Lands on the PDS authorize page (`localhost:7102/oauth/authorize`). Fill password with `tab.fill('input[type=password]', 'alice-pass-123')` — do NOT `tab.type` twice after an error (text appends → "Wrong identifier or password").
3. Consent screen: the Authorize button resists puppeteer `::-p-text` clicks — click via DOM instead:
   `tab.evaluate(() => { Array.from(document.querySelectorAll('button')).find(x => x.textContent?.trim() === 'Authorize')?.click(); })` with a `waitForNavigation` racing it. Redirects back to `127.0.0.1:3000`.

## Browser-tool gotchas hit every time
- `tab.waitFor(<number>)` THROWS (`W.trim is not a function`) — it takes a selector. Sleep with `await new Promise(r => setTimeout(r, ms))`; poll with `wait(fn)`.
- `tab.observe()` returns an object, not a string; `tab.ariaSnapshot()` returns the sliceable string.

## Verifying engagement round-trips
- Card/detail button state: `tab.evaluate` reading `.piece__bar button.act--star/.act--boost` (className, title, disabled, textContent).
- Backend reflection: `like_index` / `boost_index` rows + `artwork_index.like_count/boost_count` in psql (consumer indexes ~1–2s after the PDS write); reload the page and confirm active state persists.
- Before running `bun run e2e`, STOP the dev appview/consumer/frontend — e2e reuses the same compose projects and a second live consumer races the suite's. First e2e run after a live dev session may fail on leftover state; rerun clean.
