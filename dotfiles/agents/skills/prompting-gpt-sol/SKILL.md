---
name: prompting-gpt-sol
description: "How to delegate work to GPT 6.2 Sol through Codex in T3 Code: deciding whether a task suits Sol, writing the delegate_task brief, choosing reasoning effort, steering long multi-step work, and checking what comes back. Use whenever you are about to delegate to Sol, Codex, or another GPT model, when deciding which model should take a task, when running parallel worker agents, or when a GPT worker reports something as done, impossible, or a dead end."
---

# Delegating to GPT 6.2 Sol

## The core model

GPT is a strong engineer that needs a persistent project manager. Give it well-aimed work (implementing, fixing,
refactoring, reviewing, running experiments) and keep the direction yourself.

Inside a well-aimed task, 6.2 Sol judges well. In tests it ignored planted wrong diagnoses and red herrings,
didn't over-engineer, and reviewed honestly, even with plain prompts. Over hours, GPT models lose the plot:

- The goal drifts through side-investigations that each look reasonable.
- One dead branch gets treated as a reason to stop all the work.
- Promises to change behaviour fade within the hour.

A longer brief doesn't fix this. Someone outside GPT (you, or the user) has to hold the deliverable, decide when the whole job stops,
and challenge GPT's "dead end" and "done" claims. Inside that frame, GPT's thoroughness and insight pay off.

## Sol or Opus?

What it costs to route a task wrong is mostly the user's attention spent steering, not tokens. Opus's edge is taste, which
mostly means knowing what to drop ("weakest high-information direction", "closer framing, not new information").

- **Send to Sol:** work added to an existing codebase with a clear deliverable and an objective check: tests, a type check,
  a repro, a classification. The codebase sets the direction and the check sets the finish line, so little depends on taste.
- **Keep with Opus:** choosing direction, deciding what matters, open research, and anything that loops for hours.
  Sol can still do the individual implementation steps or experiments; see _Long-running work_.
- **Quick test:** if you can write the brief's "Done when" line right now, Sol can do it. If working out what "done"
  means is part of the task, Opus owns it.

## T3 wiring

- Always use the Codex provider: `{providerInstanceId: "codex", model: "gpt-6.2-sol"}`.
- **Codex defaults `reasoningEffort` to `low`, and low was enough for every task tested.** High effort never changed
  correctness. It added a self-check, and on a research task it returned _fewer_ options. Raise effort when there's
  evidence the task is hard (a failed attempt, a big search space, subtle invariants), not by default.
- The child sees only `task`, with no history. Everything it needs (paths, the test command, constraints) goes in the brief.
- It reliably honours "work only in <dir>" and "don't modify files".

## Writing the brief

```text
[Mode: EXECUTION | VERIFICATION | DISCOVERY]      (include when the mode isn't obvious)
Project: <abs path>. Tests: <command, and where to run it>.
Goal: <observable outcome>.
Evidence: <symptom, failing test, repro>. Suspicion (unverified): <your guess, labelled as a guess>.
Constraints: <scope, off-limits files, signatures to keep>. Work only inside <path>.
Done when: <stop condition>.
Approach: <open | fixed: ...>
Flag problems you notice outside scope; don't fix them.
Reply with: <the exact fields you want back>.
```

Why each line is there:

- **Give the evidence, not the fix.** Sol ignored a wrong diagnosis stated as fact and found the real bug (3/3).
  When the brief prescribed a symptom-patch instead, it applied it silently, never named the root cause, and introduced a new bug.
  It questions claims but follows instructions literally. If the approach has to be fixed, add: _"If this treats a symptom
  rather than the cause, implement it anyway and name the root cause and any new inconsistency it creates."_
- **Say whether to act.** It read a bare user remark ("logging is kind of noisy") as a change request and edited
  the code both times, choosing a different log level each time. For anything that isn't a change request, write "don't modify; observe and propose".
- **Always state the stop condition.** Without one it answers the literal ask: "find me one" gets one. "Done only
  when every entry is classified PASS/FAIL" got all 12 right, with cited reasons. Higher effort narrowed the answer rather than widening it.
- **"Flag, don't fix"** costs nothing and surfaces bugs it notices. Its scope is already tight, so without this line it just stays quiet about them.
- **Name the reply fields.** It fills exactly what you ask for and is terse otherwise.
- **Skip warnings it doesn't need.** On short tasks there was no over-engineering, no tangent-chasing and no rubber-stamping, so
  "don't over-abstract" and "beware red herrings" add length without changing results. "Justify every change with a project fact"
  backfired on a vague "improve this" task: it became so cautious it made only cosmetic edits.
- **For web research, define what counts as verified**, for example "a spec sheet or manual page, not a forum post",
  and ask for unverified candidates in a separate list rather than dropped. This case is untested; contained research worked fine.
- **Mode labels change the report, not the result.** VERIFICATION gives an observed-versus-inferred split. DISCOVERY with
  "rank causes by cost, check cheapest first" gives an auditable trail. Use them when you need that kind of report.

## Long-running work

Over hours, GPT's failures are about direction, not individual steps, so the fixes are about who holds the direction.

- **You hold the goal.** After each result, ask how it moves the deliverable forward. GPT will keep following leads that
  each look reasonable on their own, and it won't notice that the deliverable has stopped moving.
- **Delegate in bounded steps.** Give each delegate_task one step, with its own stop condition and budget. Short, closed
  tasks are where Sol is reliable, so break long work into a chain of them that you steer.
- **You decide when the whole job stops.** Tell the child that a dead end is a result to report, not a reason to stop.
  GPT tends to treat a local obstacle as a global one.
- **Save corrections to your project memory, then brief from it.** When the user corrects how a GPT worker behaves
  (for example "stop auditing after publish" or "don't stop at branch dead ends"), save it to your project-local memory as a
  feedback memory about prompting GPT here. Copy the relevant ones into each new brief, because every Codex child starts with
  no history. GPT's own promises to change course fade within a session; corrections only last if you carry them forward.
- **Name the process you want.** Say how much verification, documentation and polish a step needs. Without a limit,
  GPT fills the gap with ceremony.
- **Audit GPT's results yourself.** As the orchestrator, you are the auditor: challenge premises, check whether evidence
  is really independent, and decide what to drop. This is the part Opus does better than GPT. You're fallible too,
  so when your own framing might be the problem, look at the raw output rather than the child's summary, or ask the user.

## Reviewing what comes back

- **"Impossible", "dead end" and "not found" are claims too.** Ask what was actually tried before accepting one.
  GPT overclaims failure at least as often as it overclaims success.
- **Check against the real deliverable, not a proxy.** Passing tests or hitting a metric can hide output that is plainly
  wrong. Run it or look at it.
- **Status words can come before verification.** Check the diff yourself (`git diff` in the child's directory).
  Reports were accurate in the short tests, but checking costs little.
