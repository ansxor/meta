---
name: writing-prs
description: "How to write GitHub PR titles and descriptions for this user: non-overlapping H2 sections when a PR does multiple things, items as sequential <details><summary><Action-oriented change></summary>, simple/brief fixes as plain bullets, high-level justifications over trivia/numbers, inline-text SHA-pinned permalinks. Use whenever creating or editing a PR (gh pr create/edit)."
---

# Writing PRs

A PR description says what changed and why, shaped to be scanned. The code and the notes already explain how; the description doesn't repeat them.

## Voice

- **Someone else's repo:** first person ("Seems to work fine if I set it to `0`").
- **The user's own repo** (they own or maintain it, e.g. `ansxor/*`): describe the project's state, not the author. "Audio routing now follows…", not "I changed the routing…". Avoid "you" too.
- State uncertainty where it applies. In the user's own repo, without "I" ("This may flip back", "Untested, but…").
- No checkboxes or generic "Summary/Verification/Changes" headings. Use the repo's template only if it's enforced.

## Titles

Name what the PR does and the effect, including the cause when it's a fix. Long titles are fine. No conventional-commit prefix unless the repo enforces one.

## Small PRs

One or two sentences: what it changes and why, including the odd symptom that led to it. Add a screenshot for UI changes.

## Larger PRs

- When the PR does more than one distinct thing, give each its own `##` section named after that piece of work (e.g. `## Kirameki (Star Road)`, `## Audio routing and HLE output`). Sections shouldn't overlap: each change belongs in one section, and shared plumbing sits with the change that forced it.
- Introduce each section with a short prose sentence or paragraph stating what changed and the high-level symptom behind it.
- **Substantive changes go in sequential, unbolded `<details><summary>` blocks:**
  ```markdown
  <details>
  <summary><Action-oriented change></summary>

  Explanation stating why the change was made, grounded in the high-level symptom or hardware finding.
  </details>
  ```
- **Brief one-liner fixes belong in plain bullet items, not folds.** If an item can be explained completely in one sentence without needing a hidden fold, put it directly as `- <Action / fix>` after the details blocks.
- **Summary labels must be unbolded action-oriented changes, NOT nouns or categories.**
  - Bad: `<summary><strong>Channel order</strong></summary>`, `<summary>Channel order</summary>`
  - Good: `<summary>Swapped output channels at DAC</summary>`, `<summary>Switched default gain model to SingleStage</summary>`, `<summary>Rewired OTIS→ESP→DAC paths and removed 0.5x mix scaling</summary>`
  - A reader scanning down the summaries must immediately see *what happened* without clicking open anything.
- Keep details inside the fold high-level. Do not dump fine-grained benchmark numbers, frequency ranges, or register math unless absolutely necessary to grasp the change. Give the *why* conceptually ("because pair 0 is unconnected on the board and ESP feeds the DAC directly, causing low volume", not dB breakdowns and millisecond slices). Let the code and linked notes carry the fine details.
- Link inline on the prose phrase the target supports (`[bankswitches pages](…)`, `[ramp down through their release phase](…)`), not with the file name as the link text. Prefer permalinks to the specific line range in `docs/notes/…` that holds the evidence or disassembly, with code permalinks where the code itself is the point.
- All permalinks are pinned to the head commit's full SHA (`https://github.com/<owner>/<repo>/blob/<full-sha>/<path>#L<a>-L<b>`) or the external repo's pinned commit, never branch names or bare paths.
- No before/after tables, code-constant tables or implementation diagrams.

## Not in the body

Verification/test sections, CI status, file lists, implementation plans, task lists. Mention test runs and CI in chat.

## Check before pushing

- Open every permalink target at the SHA and confirm the lines are the ones meant.
- Check summary titles: are they unbolded concrete actions (`Swapped...`, `Added...`, `Removed...`, `Fixed...`) rather than category names?
- Are 1-sentence minor items in plain bullets rather than empty-feeling folds?
- Re-read the pushed body (`gh pr view <n> --json body`) to confirm it landed intact.

## Examples

Small PR:

> Weird bug but Elpaca doesn't seem to load the package because `xml+`'s version is `0.0.0` in the source file, so it rejects it because the version in the requirements is too high. Seems to work fine if I set it to `0`.

Larger PR (excerpt, user's own repo):

> ## Kirameki (Star Road)
>
> Adds [Kirameki's game config](…), along with standard 32-column playfields and text row culling in `GameVideo`.
>
> <details>
> <summary>Added sound ROM bankswitching window</summary>
>
> Kirameki is the first game here with a multi-megabyte sound ROM that [bankswitches pages](…) into the sound CPU address space via main bus writes. Audio paths, `sound-extract` and save states now read through [that banked window](…).
> </details>
>
> ## Audio routing and HLE output
>
> Comparing sound `0x187` against a [PCB recording](…) showed emulated audio was noticeably quiet, stereo channels were reversed, highs were muffled, and reverb lacked the space and decay of the board because HLE used a generic comb filter instead of the game's DSP program.
>
> <details>
> <summary>Rewired OTIS→ESP→DAC paths and removed 0.5x mix scaling</summary>
>
> Follows the [oscilloscope-traced OTIS→ESP→DAC wiring](…). Removed MAME's pair-0 aux bypass and mix-halving gain because [pair 0 is unconnected on the board and the ESP feeds the DAC directly](…), fixing the overall low volume.
> </details>
>
> <details>
> <summary>Swapped output channels at DAC</summary>
>
> [Swapped once at the DAC](…) in both backends to match PCB stereo balance. Hardware pinout for the stereo connector is unconfirmed, so this may flip back if recordings turn out to have swapped capture channels.
> </details>
>
> - Removed artificial declick tail after envelope fixes showed it had no effect on voice cuts.
> - Plain starts now [stop at bar boundaries](…) instead of looping indefinitely when unlinked.
> - Added [reverb comparison](…) and [ES5510 trace-to-graph](…) scripts used during investigation.
