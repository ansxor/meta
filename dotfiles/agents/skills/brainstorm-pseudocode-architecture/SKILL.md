---
name: brainstorm-pseudocode-architecture
description: >
  Interactive pseudocode-architecture refactor: discover the codebase,
  propose the architecture as a short pseudocode sketch, iterate on it
  with the user, and only after explicit agreement hand it to the
  implementer agent. Use when the user wants to discuss,
  review, or shape architectural improvements, codebase
  simplification, flatter hierarchies, or clearer data flow before
  any code changes.
---

# Goal

Reach an architecture the user has explicitly agreed to, then have
it implemented. The design conversation happens at the conceptual
level, as a pseudocode sketch, before any code changes.

# Before Starting

Read @skill:pseudocode-architecture@ (the principles, the design
procedure, the implementation plan format, validation).

# Procedure

1. **Design.** Run the Design Procedure from
   `pseudocode-architecture` (discover, identify unnecessary
   complexity, design the simplified architecture).

2. **Propose and review (stop here before implementing).**
   - Write the proposal as a pseudocode sketch (see Proposing the
     Architecture below).
   - Present it to the user and ask whether they agree with the
     architecture and where it could be improved.
   - Iterate on the sketch with the user: revise the types,
     messages, protocols, and mediators they pick at, and show
     only what changed each round.
   - Do not modify code until the user has explicitly agreed to
     the architecture.

3. **Write the implementation plan.** Translate the agreed sketch
   into an implementation plan in the format defined by
   `pseudocode-architecture`, in the project's language with real
   paths and symbols. Every decision made in the discussion goes
   into the plan; only genuine details stay under Open details.
   Append the agreed sketch verbatim as an appendix. Save the plan
   to `local://pseudocode-plan.md`.

4. **Implement.** Spawn the `implementer` agent with a
   task that points at `local://pseudocode-plan.md`, tells it to
   read @skill:pseudocode-architecture@ (principles,
   Implementing, Validation) first, and states the user's
   authorization scope (which public APIs may change).
   Answer its escalations yourself when the agreed design already
   settles them; bring them to the user only when they reopen
   something the user decided.

5. **Validate.** Run the Validation checklist from
   `pseudocode-architecture` yourself: run the tests and checks,
   read the entry point, and confirm the chain matches the agreed
   sketch. Send concrete defects back to the implementer
   (`write agent://<id>` while it is alive, otherwise a new
   `implementer` task with the plan plus the defect
   list) until validation passes.

6. **Report** to the user: what changed relative to the agreed
   sketch (with reasons for any deviation), and the verification
   that was run.

# Proposing the Architecture

Architecture proposals are communicated as a short pseudocode
sketch, so the user can judge the design at the conceptual level
before any code changes. Keep the sketch short, show only what is
under discussion, collapse unchanged parts to `-- unchanged`, and
hide fiddly logic behind names. Use plain, language-neutral
pseudocode: types with the messages they understand, signatures
without bodies.

A mediator is a type that holds its peers and the state of their
interaction (routing, ordering, buffering). Peers send messages to
it in dot form, and what it guarantees between them is stated next
to it. Its peers are protocols (interfaces), so its testing seam is
visible in the sketch.

A proposal contains, in this order:

1. **The entry-point chain**: the whole workflow as one chain.
2. **The types**: each intermediate representation with the
   messages it understands (signatures only, bodies elided).
3. **Protocols and mediators**: shared capabilities with their
   implementors, and each mediator with the peers it connects.
4. **Module layout**: a short tree of where each type lives.
5. **What changes**: a brief prose note comparing it with the
   current architecture, and the open questions for the user.

End by asking the user what they agree with and what they want
to change.
