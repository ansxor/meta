---
name: writing-issues
description: "How to write GitHub issues for this user: short prose paragraphs, evidence over explanation, no checklists, templates or generic closing justification. Use whenever creating or editing a GitHub issue (gh issue create/edit); for PRs use writing-prs."
---

# Writing issues

Write like a person reporting what they ran into, not a spec.

## Voice

- Short, plain prose paragraphs. Casual openers are fine ("Weird bug but…").
- **Someone else's repo:** first person, as a reporter ("I've seen this used as a CSS reset", "Seems to work fine if I set it to `0`").
- **The user's own repo** (they own or maintain it, e.g. `ansxor/*`): describe the project's state, not the author. Write "This project is developed mainly on macOS", "Changes are pushed straight to `main`", "Netplay currently uses…", not "I develop on…", "I push…", "I'd like…". Proposals become "Merging to `main` should be gated on…". Avoid "you" too ("a set has to be unzipped first", not "you have to unzip it").
- Say what's uncertain ("from my understanding", "not sure how preferred this would be"). In the user's own repo, phrase it without "I" ("This is likely…", "Untested, but…").
- No headings, checkboxes or "Background/Proposal/Acceptance" sections. Use the repo's template only if it's enforced.
- Cut anything the title already says.

## Titles

State the whole problem, including the cause and its effect when known: "Globally applied `contain: content` causes hints not to display", "Using an `UpdateView` populates the `-uploads` property with an empty dict for optional fields, causing a KeyError". Long titles are fine.

## Bug reports

- Lead with what happens, then what was expected, then the chain of consequences ("As a result, …").
- Show evidence instead of describing it. Use permalinks to the exact source lines, the actual bad value, full error output or tracebacks (redact private paths, and say you did), and before/after screenshots.
- Annotate code snippets inline to point at the failure: `# <- Errors here`, `/* where it fails */`, `/* vvvv violating property vvvv */`.
- Put reproduction commands in a fenced code block with a `#` comment above each saying what to do and what you'll see. Include the code you used when it's needed to reproduce.
- Once the bug is shown, stop. The broken behaviour is the justification.

## Feature requests

- Motivation must be concrete: the specific situation that made you want it ("I have to work with S3 keys with very large lengths", "emojis are something you usually want to activate in the flow of typing, so a slow picker is jarring"). Never a generic closing benefit ("Loading the zip directly would let a set work as downloaded").
- The desired behaviour is fine to propose. Keep it at the level of what should happen, not implementation steps. If you're undecided, a short list of options is fine, with your uncertainty stated.
- When the issue tracks a targeted set of distinct features that are all intended (e.g. "Competitive netplay Land Maker features": enforced mirrors, one-side colorblind palettes, expanded board selection, a different board RNG), list them as plain bullets: one short noun phrase each, no checkboxes, no how. Put context, sources and prior art in prose after the list.
- Point to prior art when it explains the idea (e.g. foot's `footserver`/`footclient`).

## Not in the body

Implementation plans, task lists and acceptance checklists. Bring them up in chat or a later comment when the work starts.

## Examples

Bug report:

> With `--video-backend gpu --video-scale auto-integer`, resizing or maximizing the window leaves the image stuck at about 1x instead of stepping up to the expected integer scale, so the game sits small in a large window. `--video-scale auto` resizes correctly in the same situation.
>
> ```sh
> # Start windowed, then maximize: the image stays at ~1x
> ./build/landmakr --video-backend gpu --video-scale auto-integer --video-border 48
>
> # Same steps with auto: the image scales up as expected
> ./build/landmakr --video-backend gpu --video-scale auto --video-border 48
> ```
