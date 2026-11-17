---
name: no-comments
description: >
  Delete code comments in a scoped diff or file set via a fresh-eyed
  Comment Sicko subagent, fix the root causes its MUST KILL flags
  expose, and offer type/test/lint encodings for constraints that
  comments claimed. Use when the user asks to strip, audit, or
  clean up comments, or to remove workaround/“do not remove” prose.
---

# Goal

Spawn Comment Sicko, then act on its accepted findings. Defer to its
fresh perspective: the author of the diff is the worst judge of which
comments are needed.

```
scope → comment-sicko (deletes comments, flags code) → review → root-cause fixes → report
```

# Scope

Use the files or diff the user named. Otherwise use the current diff
against the base branch (default `main`), including the working tree.

# Procedure

1. **Spawn.** Call @spawn@ with one task (default `task` agent; it needs
   edit access). The task text is
   [`references/comment-sicko.md`](references/comment-sicko.md)
   read verbatim, then the scope. Put the scope's file list or diff
   command in the task, and set `solutionSpace` to something like
   `one pass: comment deletion and flagging, rules given`. Do not
   restate the prompt's rules.

2. **Review its report and diff.** Reject:
   - application-code edits and scope escapes;
   - deletions of comments that match a keep-list exception;
   - misstated `MUST KILL` reasons;
   - flags that treat intentional, kept code as guilty.

   Accept and keep actionable: reshape flags on surprises in our own
   code (do not restore those comments). A keep survives only with
   proof that it concerns something we cannot change.

   Also audit for scoped lint and TypeScript suppressions the
   subagent missed. Suppressions guarding correctness or safety are
   actionable `MUST KILL`s.

   Restore a deletion only with the exact keep-list exception and
   scoped proof. Before accepting thin `IMPORTANT` / `do not remove`
   kills or keeps, investigate the named symbol yourself: @lsp@
   references, `grep` for callers and tests, `git log -S` /
   `git blame` for the introducing commit. If a kill is ambiguous,
   do not restore. If a keep is refuted or still ambiguous, delete
   it, except a `REVIEW` keep about an outside rule, which stays
   until someone checks that rule; report it open.

   Revert and rerun one rejected report with the failure named. If
   the rerun is also rejected, revert only its rejected findings,
   report them open, and continue with the accepted ones.

3. **Shape.** Fix trivial accepted flags directly: delete a dead
   path, drop a parameter, use the real API. If any fix needs a new
   shape (types, boundaries, extraction), read
   @skill:pseudocode-architecture@ and spawn one
   `pseudocode-planner` task for the accepted set plus surrounding
   code. Stop at its plan; step 4 implements it.

4. **Implement.** Make the smallest root-cause fix in scope and remove
   every named workaround. If the root cause is outside scope, land
   the smallest in-scope fix and report the rest open. Never widen the
   scope fence, fix instances outside it, or bolt on symptom guards.

5. **Constraint comments.** Comments saying `do not remove`,
   `do not change wording`, or `talk to X before changing` claim a
   constraint. Leave keeps about things we cannot change. For the
   rest, offer the cheapest in-scope encoding: a type, runtime check,
   test, or CI lint. Use @ask@ for approval. In a non-interactive
   run (subagent, unattended) proceed only if the caller
   pre-approved. If approved, encode then delete the comment.
   Otherwise delete it, report the constraint as unenforced, and
   sketch the out-of-scope work.

6. **Report:** deletion count, restored comments, `REVIEW` keeps,
   reruns, planner sketch, fixes, encoding offers, encodings made,
   unenforced constraints, and other open work.
