---
name: pseudocode-architecture
description: >
  Principles of "pseudocode architecture": code whose high-level flow
  reads like pseudocode, a value flowing through a chain of messages
  where each transformation belongs to the type that receives it.
  Defines the principles, the design procedure, the implementation
  plan format, and validation. Load whenever judging, designing, or
  implementing such an architecture; the workflows live in
  `brainstorm-pseudocode-architecture` (interactive) and
  `apply-pseudocode-architecture` (autonomous).
---

# Goal

Design the architecture of a codebase so that its high-level
execution flow reads almost like pseudocode.

A developer should be able to open an application's or library's
entry point and read the complete execution pipeline as a single
chain of messages sent to a value, each one turning it into the
next representation, without navigating through layers of
indirection.

Optimize for:
1. **Readability**: The code should communicate what it does.
2. **Explicit data flow**: Each intermediate representation is a
   named type, and the chain shows how one becomes the next.
3. **Shallow hierarchy**: Avoid unnecessary layers of indirection.
4. **Cohesion**: Each type owns the transformations of its own data.
5. **Maintainability**: Changes should be localized and predictable.
6. **Isolated testability**: Any component can be picked out of the
   pipeline and tested on its own.

# Architectural Principles

## 1. Three Levels of Chains

Aim for a maximum of three levels of project-defined message
chains along the primary execution path:

1. **Entry point**: One chain describing the overall workflow.
2. **Messages**: Each message in that chain is implemented by its
   receiver, and may itself be a short chain over the receiver's
   internal representations.
3. **Implementation**: The receiver's methods do the actual work.

Calls into external libraries or frameworks do not count toward
this limit.

The three-level constraint is a design target, not a reason to
create oversized methods or avoid useful types. Deep algorithms,
recursion, and genuinely complex operations may justify
exceptions.

The important property is that the complete high-level flow
remains understandable within three levels of chains.

## 2. Message-Chain Orchestration

Entry points express the workflow as a value receiving a sequence
of messages. Each message is understood by the current value and
returns the next representation.

In Smalltalk terms:

```smalltalk
request tokenize compile execute
```

In Rust:

```rust
let result = request
    .tokenize()
    .compile()
    .execute();
```

In C++:

```cpp
auto result = std::move(request)
    .tokenize()
    .compile()
    .execute();
```

Over:

```rust
let result = manager.handle(request);
```

Where `manager.handle()` delegates to another manager, which
delegates to another service, and so on.

Rules for message chains:

- **Responsibility belongs to the receiver.** A transformation is
  a method on the type whose data it primarily reads:
  `Tokens::compile(self) -> Program`, not
  `Compiler::compile(tokens)`.
- **Each intermediate representation is a named type.** `Request`,
  `Tokens`, `Program`, `Output`: nouns. Transformations are verbs
  on those nouns. A step's contract is its input type and output
  type.
- **Transformations consume their receiver.** In Rust, take `self`
  by value; in C++, use `&&`-qualified member functions or return
  by value and mark them `[[nodiscard]]`. Ownership flows down the
  chain, and stale intermediate values cannot be reused by
  accident.
- **Context is a message argument.** A step that needs a symbol
  table or config receives it explicitly:
  `tokens.compile(&symbols)` (Smalltalk: `tokens compileWith:
  symbols`). Never hide it in the receiver just to keep the chain
  short, and never pull it from global state.
- **Distinguish transformations from cascades.** A transformation
  returns a new type. A cascade (Smalltalk's `;`) sends several
  messages to the same receiver, typically to configure it; model
  cascades as methods returning `&mut Self` / `Self&`, or as a
  builder, and keep them separate from the transforming chain.
- **Fallible chains use the language's railway idiom.** Rust:
  `request.tokenize()?.compile()?.execute()`. C++:
  `std::expected` with `and_then` / `transform`. Do not make every
  type check for upstream errors.
- **Branching means a sum type or two chains.** If the chain
  forks, the step should return an enum / `std::variant` that the
  next message dispatches on, or the workflow is really two
  separate chains.

When there is no clear receiver (an operation that reads two types
equally, e.g. linking several objects together), do not attach the
method to an arbitrary participant. Either use a free function, or,
when the objects need an ongoing relationship, introduce a manager
that owns the communication between them (see Managers as
mediators below).

## Managers as Mediators

A manager is justified when it is the in-between that lets two or
more objects communicate: it owns the relationship, not either
party's data.

A legitimate manager:
- Sits between peers that should not know about each other
  (a bus between a CPU and the devices it addresses; a scheduler
  between producers and consumers; a session between a client
  and a transport).
- Owns the state of the interaction itself: routing, ordering,
  timing, buffering, the protocol both sides speak.
- Receives messages from each side and translates or forwards
  them as that protocol requires; the peers talk to it, not to
  each other.

An illegitimate manager:
- Wraps a single type and does work on that type's data that
  the type should do itself (`TokenManager::compile(tokens)`).
- Forwards calls one-to-one with no state or protocol of its own.
- Exists only to give a layer a name.

The test: if you removed the manager, would the peers have to
know about each other and coordinate directly? If yes, the
manager earns its place. If the work would simply move onto one
of the types, it belongs on that type.

## 3. Flat, Type-Centered Structure

Prefer the flattest module and directory hierarchy that remains
practical, organized around the representations in the pipeline.

- Each significant intermediate type lives with the messages it
  understands: its data and its transformations together.
- Avoid layers that exist solely to forward calls.
- Avoid managers, controllers, services, factories, and wrappers
  whose only job is to act on someone else's data; the data's own
  type should do the work. Managers that mediate communication
  between objects are the exception (see Managers as Mediators).
- Avoid abstract base classes and deep inheritance; prefer
  concrete types with plain methods, and shared protocols where
  several types genuinely understand the same message (see
  Shared Protocols).
- To add messages to an external type, use an extension trait in
  Rust or a thin newtype / free function in C++.
- Introduce modules only when they establish a meaningful boundary.
- Do not create one module per method without a compelling reason.

Flatness does not mean putting everything in one file.

## 4. Small, Cohesive Types

Decompose functionality into the smallest *meaningful* types and
messages.

Each type should:
- Represent one clear stage or concept in the data flow.
- Understand the messages that operate on its own data, and no
  others (a method that mostly reads another type's fields belongs
  on that type).
- Expose a minimal, understandable interface.
- Avoid hidden state changes and implicit dependencies.
- Be independently understandable and testable where practical.

Do not split methods merely to minimize length, and do not invent
intermediate types that carry no meaningful distinction. Each
abstraction should reduce complexity, not redistribute it.

## 5. Explicit Data Flow

Prefer architectures where inputs, intermediate representations,
and outputs are visible as types in the chain.

- Make transformations explicit as messages that change type.
- Pass required context as message arguments rather than
  retrieving it from global state.
- Minimize mutable shared state.
- Make ownership and lifetime relationships understandable;
  consuming receivers make them visible in the chain itself.
- Keep control flow predictable.
- Avoid unnecessary dependency injection and indirection.

A developer should be able to trace how data moves through the
system by reading the chain at the entry point and the type
signatures of its messages.

## 6. Avoid Artificial Abstractions

An abstraction is justified when it:
- Encapsulates meaningful complexity.
- Establishes a useful architectural boundary.
- Eliminates significant duplication.
- Provides genuine extensibility.
- Makes the overall system easier to understand.

Otherwise, prefer the simpler implementation.

Do not optimize for design patterns, inheritance hierarchies,
or architectural purity at the expense of readability.

## 7. Isolated Testability

It should be easy to pick any component out of the system and test
it on its own, without building the rest of the pipeline.

- **Every intermediate type is directly constructible.** A test for
  `Tokens::compile` builds a `Tokens` by hand; it does not have to
  start from a `Request` and run `tokenize` first.
- **A transformation is tested as input type → output type.**
  Construct the receiver, send the message with its arguments,
  assert on the value returned. Consuming receivers and explicit
  context arguments make this the whole test.
- **Side effects live at the ends of the chain.** I/O, clocks,
  randomness, and other external state are read at the start or
  written at the end, or passed in as arguments, so the middle of
  the pipeline is pure and deterministic.
- **Mediators talk to their peers through protocols.** A manager
  that sits between objects depends on traits / concepts for each
  side, so a test can plug in fake peers and observe exactly what
  the manager sends and receives. Peers, in turn, can be tested
  without the mediator.
- **No hidden setup.** If a component cannot be tested without
  global state, a running service, or a long chain of other
  components, its dependencies are not explicit enough; make them
  message arguments or protocol boundaries.

Mediator boundaries and other seams where a test must substitute
one side are one of the two places protocols belong; the other is
genuine commonality between types (see Shared Protocols).

## 8. Plain Methods, Shared Protocols

**Plain methods are the default.** A message is an inherent method
on the type that receives it (`impl Tokens { fn compile(self) ->
Program }`). Do not wrap a single type's method in a trait or
concept just to give it a name.

**Actively look for what types have in common.** Polymorphism is a
readability tool: when several types understand the same message
with the same meaning, naming that message as a protocol tells the
reader "these are the same kind of thing" and lets code be written
once against the protocol.

- When reviewing or designing, compare the messages each type
  understands. Repeated method names and parallel signatures
  across types are signs of a shared protocol waiting to be named.
- Choose between a protocol and a tagged union by whether the set
  is open: a closed, known set of cases that code will `match` /
  `switch` over is a tagged union (enum / `std::variant`); an open
  set that new types will join later is a protocol. A match whose
  every arm performs the same operation on a set that keeps
  growing is the signal to convert it into a protocol.
- Name the protocol after the capability, not the implementors
  (`Render`, `Step`, `Encode`, `MemoryMapped`).
- Write orchestration and mediators against the protocol when
  they work the same way for every implementor; this keeps the
  chain readable as "anything that can do X".
- Use the language's static polymorphism by default (Rust generics
  and traits, C++ concepts and templates); reach for dynamic
  dispatch (`dyn Trait`, virtual functions) only when the set of
  types is open or chosen at runtime.

**The commonality must be real.** Two methods that share a name but
mean different things are not a protocol, and forcing them into one
is an artificial abstraction (principle 6). The test: can a caller
use any implementor through the protocol without knowing which one
it has, and get the behavior it expects?

Protocols therefore appear in two places: where types genuinely
share a capability, and at seams a test or alternative
implementation needs to substitute (principle 7). Everywhere else,
plain methods.

# Design Procedure

Both workflows design the architecture the same way; they differ
only in who decides (the user in
`brainstorm-pseudocode-architecture`, the planner in
`apply-pseudocode-architecture`).

1. **Discover the architecture**
   - Identify the public entry points.
   - Trace the primary execution paths.
   - Identify the important data structures and the
     representations data passes through.
   - Understand existing tests, invariants, and performance
     constraints.

2. **Identify unnecessary complexity**
   - Excessive call depth.
   - Redundant forwarding functions.
   - Manager / service types acting on a single type's data
     (as opposed to mediating between objects).
   - Peers coupled directly to each other where a mediating
     manager should own their communication.
   - Types that understand the same message with no named
     protocol connecting them (duplicated orchestration, or a
     switch over a growing set of similar types).
   - Traits / concepts with a single implementor and no testing
     seam, which should be plain methods.
   - Methods living on the wrong type.
   - Overly nested modules.
   - Unnecessary abstractions.
   - Hidden dependencies or state.
   - Fragmented execution flow.

3. **Design the simplified architecture**
   - Sketch the ideal workflow as a message chain.
   - Name each intermediate representation as a type.
   - Assign each transformation to the type that receives it.
   - Identify messages several types share and name them as
     protocols.
   - Decide which steps are fallible, which branch, and what
     context each needs as arguments.
   - Choose the simplest practical module hierarchy.
   - Compare the proposed architecture with the existing one.

# Implementation Plan

The design is handed to the `implementer` agent as an
implementation plan. The plan is the contract between whoever
designed the architecture and the implementer: it fixes the
architecture and leaves only details open. Write it in the
project's language and idioms, with real file paths and symbol
names, in this order:

1. **Scope**: paths in and out of scope, public APIs that must be
   preserved (or the explicit authorization to change them), and
   the build, test, and lint commands.
2. **Entry-point chain**: the target chain as it will appear in
   code.
3. **Types**: each intermediate representation with its file, the
   data it owns, and the messages it understands as signatures in
   the project's language; for each message, the existing code it
   absorbs (`old::path::symbol → Type::message`).
4. **Protocols and mediators**: each protocol with its
   implementors; each mediator with the peers it connects, the
   interaction state it owns, and the guarantees it keeps.
5. **Removals**: types, functions, modules, and files to delete,
   and the callers to migrate.
6. **Module layout**: a short tree of where each type lives.
7. **Steps**: an ordered list where each step leaves the build
   green; mark steps that touch disjoint files as independent.
8. **Verification**: behavior to preserve, existing tests to run,
   and the focused isolation tests to add for each new type and
   mediator.
9. **Open details**: decisions deliberately left to the
   implementer (naming of private helpers, error-type plumbing,
   test fixtures, and the like).

# Implementing

- Restructure code around the plan, translating it faithfully
  into the project's language and idioms.
- Move behavior onto the types whose data it uses.
- Remove obsolete abstractions and unnecessary indirection; migrate
  every caller, leave no shims.
- Preserve existing behavior and public APIs unless changes are
  explicitly authorized.
- Avoid unrelated feature changes.

# Validation

- Run relevant tests and static checks.
- Check for performance regressions where applicable (moves
  through the chain should not introduce copies).
- Confirm each intermediate type and each mediator can be tested
  in isolation; add focused tests where they are missing.
- Confirm that the entry-point chain reads as the workflow.
- Review whether each remaining type and message is justified.

# Expected Result

The resulting codebase should have:

- An entry point that reads as a single message chain.
- A clear, mostly linear pipeline of named representations.
- Behavior owned by the types whose data it transforms.
- Managers only where they mediate communication between objects.
- Components that can each be constructed and tested in isolation.
- Plain methods by default, with named protocols wherever types
  genuinely share a capability.
- A shallow, type-centered module hierarchy.
- Explicit context passed as message arguments.
- Minimal unnecessary indirection.
- Preserved functionality and performance characteristics.

**The ultimate measure of success is how quickly a developer
can understand the system, not how few functions or files it has.**
