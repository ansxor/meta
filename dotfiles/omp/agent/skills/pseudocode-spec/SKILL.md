---
name: pseudocode-spec
description: Reference for Darien's keyword-delimited, Nim/Ada-flavoured pseudocode dialect, used strictly to communicate high-level designs and processes. Use when reading or writing conceptual pseudocode, sketching designs, or when a prompt says "pseudocode-spec".
---

# Spec Pseudocode

A pseudocode dialect used **strictly as a high-level communication device**:
for talking through concepts, designs and processes with people and models.
It is not a programming language, not an implementation spec, and never
compiled. It borrows Nim's types, purity markers and dot-call syntax, Ada's
constrained types and labeled `end`s, and ML's tagged unions. Meaning comes
first; exact syntax is forgiving.

## Scope

- **Use it for** the conceptual layer: architecture, data shapes, process
  flow, responsibilities, failure modes, invariants.
- **Don't use it for** algorithms, numeric work, performance-sensitive or
  low-level code, or anything whose behaviour lives in the details. Use prose
  or the real language there.
- **Keep sketches short.** A sketch should fit on a screen and read in one
  pass. If it keeps growing, split it; past that point it has become code.
- **Never treat it as source.** It is not saved as code in a project and is
  not the source of truth; the real code and docs are.

## How agents should treat it

- **It is not Nim, Ruby, or Ada.** Don't import those languages' semantics,
  stdlib, or memory model. Read it as a precise sketch.
- **It is deliberately high-level.** Math, magic numbers and fiddly logic are
  hidden behind names (see *Abstraction level*). Those gaps are intentional.
- **Signatures and constraints are authoritative.** Types, ranges, predicates,
  invariants, purity (`func`/`proc`), and pragmas like `{.raises.}` are design
  decisions. Preserve them when implementing.
- **Bodies are intent.** Prose comments and `…` mean "do the obvious thing
  here". Fill them in sensibly in the target language.
- **When implementing**, translate faithfully into the project's actual
  language and idioms. Don't write Nim or Ada unless asked.
- **When replying in pseudocode**, use this dialect and keep the same
  conventions. Lead with types and signatures, then bodies. Prefer dot
  notation, and stay at the same level of abstraction.
- **If something is ambiguous**, ask or state the assumption. Don't silently
  pick a reading.

## Abstraction level

This dialect describes **what exists, what flows where, what can fail, and
what must hold**. It does not describe how to compute things. Low-level
detail goes behind a name.

- **Math and formulas** become a named `func` with a one-line description
  or a contract saying what it guarantees.

  ```
  -- not this:
  let score = 0.6 * sim + 0.3 * recency - 0.1 * log(d.len)

  -- this:
  func relevance(d: Doc, q: Query): Ratio  -- similarity and recency, penalize length
  let score = d.relevance(q)
  ```

- **Magic numbers** become named constants. Leave the value elided if it
  isn't decided yet.

  ```
  const Max_Retries = …        -- small; tune later
  const Context_Budget = …     -- fits the smallest model's window
  ```

- **Index arithmetic, bit manipulation, parsing details, algorithm
  internals** become a named operation: `buf.next_frame`,
  `xs.stable_sort_by(priority)`, `header.decode`. Use contracts to pin down
  what matters about the result.

- **Literals that carry meaning are fine**: domain bounds that define a type
  (`Percent = int range 0 .. 100`), enum-like strings, small structural
  counts ("pick 2 reviewers").

Rule of thumb: if a line makes the reader compute something in their head,
give it a name.

For agents: when implementing, fill these gaps with precise logic, pick
sensible values, and state any constants you assumed. When writing
pseudocode, don't descend into formulas; if exact math matters, put it in a
separate note or real code, not here.

## Focus: show only what's being discussed

Leave out anything outside the focus of the current discussion. A stage,
routine or block whose internals don't matter right now shrinks to a
signature, a `…`, or a one-line comment. Don't fill it in just because you
could.

For example, when discussing a pipeline's design, what matters is the
stages, what flows between them, and where things branch or fail, not what
each stage does inside:

```
-- stages: internals out of scope
proc ingest(src: Source): stream[RawDoc]
func clean(d: RawDoc): opt[Doc]              -- drops unusable docs
func chunk(d: Doc): seq[Chunk]
proc embed(cs: seq[Chunk]): seq[Vector] {.raises: [RateLimited].}
proc store(vs: seq[Vector])

-- the part being discussed: how data moves
proc index(src: Source) do
  src.ingest
    .filter_map(clean)
    .flat_map(chunk)
    .batch(Embed_Batch)
    .map(embed)           -- RateLimited: back off, retry the batch
    .for_each(store)
end index
```

Ways to omit, from most to least:

1. A comment in place of a whole section: `-- auth and logging as today`
2. A signature with no body
3. A body of just `…`
4. A prose comment summarising the logic

For agents: when replying, sketch only the part under discussion and
collapse the rest. When reading, an omitted part means "out of scope here"
(unchanged, or not decided yet), never "empty" or "remove it". When
discussing a change, show what changes and collapse the rest to
`-- unchanged`.

## Comments and elision

```
-- line comment
…            -- elided detail: "the obvious thing"
-- prose may replace logic inside a body:
--   pick the cheapest model that satisfies the constraints
```

## Bindings

```
const Limit = …    -- named constant (value may be elided)
let x = y.parse    -- immutable
var n = 0          -- mutable
n = n + 1          -- reassignment
a == b, a != b     -- comparison
and, or, not       -- boolean ops (words, not symbols)
```

## Dot notation (uniform call syntax)

As in Nim, a call's first argument can be written before the routine with a
dot. The two forms are the same call:

```
withdraw(acct, amt)   ≡   acct.withdraw(amt)
len(xs)               ≡   xs.len          -- no other args: parens optional
```

**Prefer the dot form** whenever a routine acts on, queries, or transforms
an object. Read `x.f(…)` as "send `f` to `x`". It reads left to right, and
chains form pipelines:

```
let report = tasks
  .filter(is_urgent)
  .map(plan)
  .flatten
  .summarize
```

Leading dots on continuation lines are fine for long chains.

Keep the free-function form when no argument is clearly the subject:

```
max(a, b)
distance(p, q)
Task(goal: "x", budget: Default_Budget)    -- constructors
```

Declarations still list the receiver as the first parameter. There are no
classes or methods; dot notation is purely call syntax:

```
proc withdraw(var acct: Account, amt: Money)   -- called as acct.withdraw(amt)
```

When implementing, map dot calls onto the target language's natural form:
methods, extension functions, traits, or plain functions.

## Types

```
type Tokens = distinct int            -- new type, not interchangeable with int

type Task = record
  goal: string
  budget: Tokens
end record

type Outcome = Solved(answer: string) | Escalate(why: string) | Retry
                                      -- tagged union; variants may carry fields

type Mode = enum Fast, Careful, Exhaustive end enum

seq[T]        -- ordered list
set[T]        -- unordered unique collection
map[K, V]     -- dictionary
opt[T]        -- may be absent (none / some(x))
stream[T]     -- values arriving over time (lazy / async sequence)
T | U         -- untagged union, use sparingly
```

## Constraints (Ada-style)

Constraints narrow the set of legal values. They are part of the design:
a value that violates one is a bug or a rejected input, never a value to
silently carry around.

### Subtypes vs distinct types

```
subtype Percent = int range 0 .. 100           -- still an int; usable where int is
type    Port    = distinct int range 1 .. 65535 -- new type; not mixable with int
```

- `subtype` = the base type plus a constraint. Compatible with its base.
- `distinct` = a new type, optionally constrained. Not compatible with its base.

### Ranges

```
subtype Natural  = int range 0 .. inf          -- built in
subtype Positive = int range 1 .. inf          -- built in
subtype Ratio    = float range 0.0 .. 1.0
subtype Weekday  = Day range Mon .. Fri        -- slice of an enum
subtype Attempts = int range 1 .. Max_Retries  -- bounds may be named constants
```

`a .. b` is inclusive. `inf` / `-inf` mean unbounded on that side.

### Predicates

Arbitrary conditions on a value. `it` names the value being checked.

```
subtype Username    = string where it.is_valid_handle
subtype Sorted[T]   = seq[T] where it.is_sorted
subtype NonEmpty[T] = seq[T] where it.len > 0
```

Keep predicates readable; hide fiddly checks behind a named `func`.

### Inline constraints

Constraints can go directly on fields, parameters, and results:

```
type Retry_Policy = record
  attempts: Attempts
  backoff:  Duration where it > 0
end record

func sample(xs: NonEmpty[float], p: Ratio): float
```

### Invariants

A condition over a whole record that must hold whenever the value is
observable from outside (after construction, between public operations).

```
type Window = record
  lo, hi: int
invariant lo <= hi
end record
```

### Discriminants

A record parameterised by a value that shapes or constrains its contents:

```
type Buffer(cap: Positive) = record
  data: array[cap] of byte
  used: int range 0 .. cap
end record
```

### Implementing constraints

Agents should map constraints onto whatever the target language does best:
refined/newtype wrappers with validating constructors, enums, `assert`s at
boundaries, schema validation (e.g. at API or file-parsing edges), or
property tests. Validate once at the boundary where a value enters, then
trust the type inside.

## Typestate

A value's lifecycle stage is part of its type. Transitions are routines
that take one stage and return the next, so the legal order of operations
can be read from the signatures alone.

```
type Stage = enum Draft, Submitted, Approved, Published end enum

type Doc[S: Stage] = record
  body: Text
  …
end record

func submit(d: Doc[Draft]): Doc[Submitted]
proc approve(d: Doc[Submitted]): Doc[Approved] {.raises: [Rejected].}
proc publish(d: Doc[Approved]): Doc[Published]
func preview(d: Doc[Draft | Submitted]): Page   -- accepts several stages
```

- A routine accepts only the stages it names. Calling `d.publish` on a
  `Doc[Draft]` is a design error, not a runtime case to handle.
- Transitions consume the old value: after `let s = d.submit`, `d` is no
  longer meant to be used.
- When stages carry different data, use a tagged union per stage instead
  of one record with optional fields.

Implementing: phantom type parameters, one type per stage, the typestate
or builder pattern, or, where the language can't express it, a stage enum
checked at the boundary.

## Polymorphism (typeclasses)

Polymorphism is expressed with **typeclasses**: a named set of operations a
type can support, plus **explicit instances** saying which types support
it. There are no classes or inheritance; data stays in records and unions.

### Declaring a typeclass

```
typeclass Model[M]
  func name(m: M): string
  func window(m: M): Tokens
  proc complete(m: M, p: Prompt): Reply {.raises: [Timeout].}
    ensures result.len <= m.window
  func describe(m: M): string do       -- body given = default implementation
    …
  end describe
end Model
```

Operations can carry contracts like any other routine. Because the first
parameter is the instance type, dot notation works as usual:
`m.complete(p)`.

### Instances

Instances are always declared explicitly. Nothing implements a typeclass
just because its shape happens to match.

```
instance Model[Claude]                  -- details out of scope
instance Model[Local_Llama]
  func window(m: Local_Llama): Tokens do … end window
  …
end instance

instance[S: Stage] Show[Doc[S]]         -- one instance for every stage
```

A bare `instance` line with no body means "this type supports it; how is
out of scope".

### Using a typeclass

```
func first[T](xs: seq[T]): opt[T]                 -- any T at all
func cheapest[M: Model](ms: NonEmpty[M]): M       -- any M with a Model instance
func render[T: Show and Hash](x: T): Page         -- several requirements
typeclass Chat_Model[M]: Model[M] … end Chat_Model -- requires Model too
```

`[M: Model]` is resolved **statically**: each call works with one concrete
type. For a mix of types at run time, use `any`:

```
let pool: seq[any Model] = [claude, llama]       -- dispatch per value
```

### Typeclass or tagged union?

- **Tagged union** when the set of cases is closed and known now, and code
  will `case` over them.
- **Typeclass** when the set is open: new types will be added later, by
  you or others, without touching existing code.

### Common typeclasses

`Eq`, `Ord`, `Hash` and `Show` can be assumed without being declared.

Implementing: map typeclasses onto the target language's equivalent: Rust
traits (`any` → `dyn`), Haskell classes, Swift protocols, Scala givens, Nim
concepts, or Go/Java/TypeScript interfaces. Where none exists, pass a
record of functions.

## Routines

```
func cost(p: Plan): Tokens            -- pure: no effects, same input → same output
proc run(s: Step): Outcome {.raises: [Timeout, Refused].}
                                      -- has effects; lists failure modes
proc fetch(u: Url): async Page        -- asynchronous
func first[T](xs: seq[T]): opt[T]     -- generic (see Polymorphism)

proc orchestrate(t: Task): Outcome do
  …
end orchestrate                       -- labeled end names the routine
```

A signature with no body is a declaration: "this exists, behaves like this".

Annotations on a routine are Nim-style pragmas, `{. … .}`, placed after the
return type. Several can share one pragma, separated by commas:

```
proc serve(var q: Queue) {.raises: [Shutdown], always: q.len <= Max_Queue.}
```

### Contracts

Pre/postconditions on a routine (the routine-level counterpart of type
constraints). `result` names the return value; `old(x)` is x on entry.
Contracts are the preferred way to say what a hidden computation guarantees
without spelling it out.

```
func split(b: Tokens, n: Positive): seq[Tokens]
  ensures result.len == n and result.sum == b

proc withdraw(var acct: Account, amt: Money)
  requires amt <= acct.balance
  ensures acct.balance == old(acct.balance) - amt
```

## Temporal properties

Constraints and contracts say what holds at one point. Temporal properties
(TLA+-style) say what holds over the whole life of a running process,
which is usually what matters for orchestration, queues and pipelines.

They are written as Nim-style pragmas:

```
{.always: P.}         -- P holds in every state                  (safety)
{.never: P.}          -- same as always not P                    (safety)
{.eventually: P.}     -- P becomes true at some point            (liveness)
{.leads_to: P, Q.}    -- whenever P holds, Q eventually follows  (liveness)
{.until: P, Q.}       -- P keeps holding at least until Q
```

Name each one with `property` so it can be referred to in discussion. A
property can range over a collection with `[x in xs]`:

```
module Job_Queue
  property bounded                  {.always: queue.len <= Max_Queue.}
  property no_loss[j in submitted]  {.always: j in (queued or running or finished).}
  property progress[j in submitted] {.leads_to: j.submitted, j.finished.}
  property retries[j in jobs]       {.always: j.attempts <= Max_Retries.}
  property no_double[j in jobs]     {.never: j.workers.len > 1.}
end Job_Queue
```

A temporal pragma can also go directly on a long-running routine, where it
holds for as long as the routine runs:

```
proc serve(var q: Queue) {.always: q.len <= Max_Queue.}
```

- Safety (`always`, `never`) means nothing bad ever happens. Liveness
  (`eventually`, `leads_to`) means something good eventually happens. Say
  which one you mean when it matters.
- Attach properties to the module or routine that describes the running
  system.

Implementing: agents don't try to prove these. They map them onto runtime
monitors and assertions, timeouts and watchdogs for liveness, tests or
simulations, or a model checker such as TLA+ when asked.

## Control flow

Every block opens with a keyword and closes with a **labeled `end`**.

```
if t.budget_exhausted then
  return Escalate("out of tokens")
elif t.is_risky then
  …
else
  …
end if

for step in t.plan do
  …
end for

while not done do
  …
end while

case step.run of
  Solved(a)     then continue
  Escalate(why) then return t.ask_stronger_model(why)
  Retry         then …
end case
```

Short one-liners are fine inline, including inside prose:
`if cache.has(key) then return cache.get(key) end if`.

## Errors

```
try
  let page = u.fetch
except Timeout then
  return Retry
end try
```

`{.raises.}` in a signature is the contract; `try … end try` is the handling.

## Modules / grouping (optional)

```
module Scheduler
  func plan(t: Task): seq[Step]
  proc dispatch(s: Step): Outcome
end Scheduler
```

## Worked example

```
const Max_Budget  = …          -- per-task ceiling
const Max_Retries = …          -- small

type
  Tokens = distinct int range 0 .. Max_Budget
  Task = record
    goal:    string where it.len > 0
    budget:  Tokens
    retries: int range 0 .. Max_Retries
  end record
  Outcome = Solved(answer: string) | Escalate(why: string) | Retry

func plan(t: Task): NonEmpty[Step]            -- pure decomposition
proc run(s: Step): Outcome {.raises: [Timeout].}

proc orchestrate(t: Task): Outcome do
  for step in t.plan do
    case step.run of
      Escalate(why) then return t.ask_stronger_model(why)
      Retry         then …                    -- retry with backoff, up to t.retries
      Solved(a)     then continue
    end case
  end for
  return Solved(t.summarize)
end orchestrate
```

## Prompt header

Paste this at the top of a prompt when the agent may not have this skill loaded:

```
-- Pseudocode conventions (high-level communication only; not code, not compiled):
--   only the part under discussion is shown; omitted parts are out of scope, not empty
--   math, magic numbers and fiddly logic sit behind named funcs/consts; fill them in
--   func = pure, proc = has effects; `{.raises: [X].}` marks failure modes
--   blocks close with labeled ends: end for, end case, end <name>
--   A | B(x: T) = tagged union; `…` = elided detail
--   x.f(a) ≡ f(x, a) (Nim-style); prefer the dot form when acting on an object
--   constraints are binding: `range a .. b`, `where <pred on it>`,
--     `invariant`, `requires` / `ensures`; subtype = compatible, distinct = new type
--   typestate: Doc[Draft] → Doc[Submitted]; signatures fix the legal order of steps
--   polymorphism via typeclasses: `typeclass Model[M] … end Model`, explicit
--     `instance Model[Claude]`, `[M: Model]` = static, `any Model` = runtime dispatch
--   temporal pragmas: {.always: P.} {.never: P.} {.eventually: P.} {.leads_to: P, Q.}
--     {.until: P, Q.}; named as `property name[x in xs] {.always: ….}`
--   comments inside bodies may replace logic with prose
```
