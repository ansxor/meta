---
name: apply-pseudocode-architecture
description: >
  Autonomous pseudocode-architecture refactor with no user discussion:
  the pseudocode-planner agent (the `slow` model role, xhigh) designs the
  architecture and writes an implementation plan, the
  implementer agent (Sonnet 5.5, vibe-style director)
  implements it and resolves details, then the result is validated.
  Use when the user asks to apply, just do, or autonomously carry out
  an architectural refactor, codebase simplification, or flattening
  without reviewing a proposal first.
---

# Goal

Apply the `pseudocode-architecture` principles to the requested
scope end to end, without a proposal round or check-ins with the
user. Planning and implementation are separate agents so that the
architecture is decided once, by the strongest planner, and the
implementer works against a fixed contract.

```
request → pseudocode-planner (+ Alloy model) → plan → implementer → validated refactor → no-comments pass
```

# Rules

- Do not ask the user questions, present proposals, or wait for
  approval. Resolve ambiguity from the code, tests, docs, and
  history; when that is not enough, choose the conservative option
  and record it in the report.
- Public APIs are preserved unless the user's request authorizes
  changing them. Pass that authorization verbatim to both agents.
- Read `skill://pseudocode-architecture` before starting; the
  Validation checklist below comes from it.

# Procedure

1. **Plan.** Spawn one `pseudocode-planner` task. Its task states
   the scope (paths, entry points, or subsystem from the user's
   request), the API authorization, and any constraints the user
   gave. The planner returns an implementation plan in the format
   defined by `pseudocode-architecture`. Save the returned plan
   verbatim to `local://pseudocode-plan.md`.

   The task MUST also instruct the planner to model the new
   architecture in Alloy (https://alloytools.org/) and verify it
   before returning the plan: declare the types, protocols, and
   mediators as signatures, the entry-point chain and its
   invariants (e.g. no cycles between modules, each step has one
   owner, every protocol has a mediator, preserved public API
   still reachable) as facts/predicates, and run `check`/`run`
   commands with the Alloy Analyzer (CLI jar, e.g.
   `java -jar alloy.jar exec model.als`). Counterexamples MUST be
   resolved by revising the architecture, not by weakening the
   model. The plan includes the `.als` model (saved next to it as
   `local://pseudocode-model.als`) and the commands/results that
   were run. If Alloy cannot be run in the environment, the
   planner states exactly what was tried and still delivers the
   model, flagged as unchecked.

2. **Implement.** Spawn one `implementer` task pointing
   at `local://pseudocode-plan.md` and telling it to read
   `skill://pseudocode-architecture` (principles, Implementing,
   Validation) first, repeating the API authorization. The
   implementer decides details on its own and escalates only
   deviations that would change the entry-point chain, a type, a
   protocol, or a mediator in the plan.

3. **Resolve escalations.** Send an architectural escalation to the
   planner (`write agent://<planner-id>` while it is alive,
   otherwise a new `pseudocode-planner` task with the plan and the
   question). Update `local://pseudocode-plan.md` with the answer
   and pass it to the implementer. Do not decide architecture
   yourself, and do not involve the user.

4. **Validate.** Run the Validation checklist from
   `pseudocode-architecture` yourself: run the tests and static
   checks, read the entry point, and confirm the chain matches the
   plan. Send concrete defects back to the implementer (`write
   agent://<id>` while it is alive, otherwise a new
   `implementer` task with the plan plus the defect
   list) until validation passes.

5. **Strip comments.** As the final pass, once validation has
   passed, run `/skill:no-comments` (read `skill://no-comments`
   and follow it) scoped to the files the refactor changed. Re-run
   the tests and static checks afterward; fix any breakage it
   causes.

6. **Report**: the entry-point chain before and after, the types,
   protocols, and mediators introduced or removed, the conservative
   choices made in place of asking, any deviations from the plan,
   the Alloy model and its check results, and the verification that
   was run (including the no-comments pass).
