---
name: complete-task
description: >
  Runbook to take a high-level task description to done: clarify the
  request if needed, have the task-planner agent (the `slow` model
  role) research and plan it, have the implementer agent build it,
  verify, then refactor: a no-comments pass always, followed by
  apply-pseudocode-architecture when the change created its own new
  concepts. Use when the user invokes /complete-task or asks to fully
  complete a task including the cleanup/refactor pass.
---

# Goal

Deliver the requested change end to end, then refactor it before
calling it complete. Planning and implementation are separate agents
so feasibility, constraints, and code style are decided once by the
strongest model, and the implementer works against a fixed plan.

```
request → clarify? → task-planner → plan → implementer → verify
        → no-comments → [new world? apply-pseudocode-architecture] → verify → report
```

# Rules

- The only user interaction is step 1. After the request is clear,
  do not ask the user anything; resolve ambiguity from the code,
  tests, docs, and history, choose the conservative option, and
  record it in the report.
- Public APIs are preserved unless the user's request authorizes
  changing them. Pass that authorization verbatim to every agent.
- Do not plan, implement, or decide architecture yourself; route
  each through its agent. You orchestrate, review, and verify.
- The task is not complete until the refactor pass has run and
  verification passes after it.

# Procedure

1. **Clarify.** Read the request. It is clear enough when you can
   state: the end-to-end behavior when done, the scope (subsystem,
   paths, or entry points), and how success is observed. Fill gaps
   from the repo first (`find`, `grep`, docs). If any of the three
   is still undetermined, or the request admits materially
   different readings, use `ask` once with every open question
   batched, offering the concrete readings you found as options.
   Do not ask about anything the repo answers. Write the settled
   request (behavior, scope, success criteria, API authorization,
   user constraints) to `local://task-request.md`.

2. **Plan.** Spawn one `task-planner` task pointing at
   `local://task-request.md`. The planner researches, establishes
   feasibility, sets constraints and code-style guidance, and
   returns a plan including a `New world` verdict. Save the plan
   verbatim to `local://task-plan.md`.

   If the plan names a blocker that makes the request impossible as
   stated, stop and report it to the user with the evidence; do not
   implement a reduced version.

3. **Implement.** Spawn one `implementer` task pointing at
   `local://task-plan.md`, repeating the API authorization. The
   implementer decides open details itself and escalates only
   conflicts with the plan's goal, constraints, steps, or
   interfaces.

4. **Resolve escalations.** Send each escalation to the planner
   (`write agent://<planner-id>` while it is alive, otherwise a new
   `task-planner` task with the plan and the question). Update
   `local://task-plan.md` with the answer and pass it to the
   implementer.

5. **Verify.** Run the plan's Verification yourself: build, tests,
   static checks, and the smoke run, observing the result. Read the
   key changed files against the plan's Constraints and Code style.
   Send concrete defects back to the implementer (`write
   agent://<id>` while it is alive, otherwise a new `implementer`
   task with the plan plus the defect list) until it passes. Record
   the changed file set (`git diff --name-only` against the starting
   point, plus new untracked files); it is the refactor scope.

6. **Refactor.** Decide whether the change created its own world:
   significant new files, a feature, or a concept with its own
   vocabulary (domain types, protocols, state machines, a subsystem
   other code talks to through them). Start from the plan's
   `New world` verdict and confirm it against what actually landed.

   1. **No-comments, always.** Read `skill://no-comments` and follow
      it, scoped to the changed file set. Its flags fix root causes
      in the current architecture before anything is restructured.
      Re-run the plan's Verification afterward.
   2. **New world only:** read `skill://apply-pseudocode-architecture`
      and follow it, scoped to the changed file set as it stands
      after step 6.1, with the same API authorization. Pass it the
      no-comments report so the planner sees the fixes already made
      and the open items. Its own closing no-comments pass covers
      the restructured code.

7. **Re-verify.** Re-run the plan's Verification after the refactor.
   Fix breakage through the agent that caused it until it passes.

8. **Report:** the settled request, the clarifications asked (if
   any), the plan summary and conservative choices, deviations and
   escalations, the `New world` decision and why, what the refactor
   changed (architecture chain before/after when applied; comment
   deletion count and open items from no-comments), files touched,
   and the verification commands with their observed results before
   and after the refactor.
