---
name: zachary-pseudocode-architecture
description: >
  Use when the user requests architectural improvements, codebase
  simplification, structural refactoring, flatter hierarchies,
  clearer data flow, or more readable and maintainable code.
  The goal is to make the architecture read like pseudocode.
---

# Goal

Design the architecture of a codebase so that its high-level
execution flow reads almost like pseudocode.

A developer should be able to open an application's or library's
entry point and understand the complete execution pipeline without
having to navigate through many layers of abstraction.

Optimize for:
1. **Readability**: The code should communicate what it does.
2. **Explicit data flow**: Data transformations and dependencies
   should be easy to follow.
3. **Shallow hierarchy**: Avoid unnecessary layers of indirection.
4. **Cohesion**: Each component should have one clear responsibility.
5. **Maintainability**: Changes should be localized and predictable.

# Architectural Principles

## 1. Three-Level Execution Flow

Aim for a maximum of three levels of project-defined function calls
from an application's or library's entry point along the primary
execution path.

For example:

1. **Entry point**: Defines the overall workflow.
2. **Operations**: Implement the major stages of the workflow.
3. **Implementation**: Perform the actual work.

Calls into external libraries or frameworks do not count toward
this limit.

The three-level constraint is a design target, not a reason to
create oversized functions or avoid useful abstractions. Deep
algorithms, recursion, and genuinely complex operations may
justify exceptions.

The important property is that the complete high-level flow
remains understandable within three levels.

## 2. Pseudocode-Like Orchestration

Entry-point functions should describe **what happens and in
what order**, rather than being dominated by implementation details.

Prefer:

```python
def process(request):
    tokens = tokenize(request)
    program = compile(tokens)
    result = execute(program)
    return result
```

Over:

```python
def process(request):
    return manager.handle(request)
```

Where `manager.handle()` delegates to another manager, which
delegates to another service, and so on.

The main execution path should be visible without navigating
through chains of trivial forwarding functions.

## 3. Flat, Cohesive Structure

Prefer the flattest module and directory hierarchy that remains
practical.

- Organize code around meaningful responsibilities and data flow.
- Avoid layers that exist solely to forward calls.
- Avoid unnecessary managers, controllers, factories, wrappers,
  and abstract base classes.
- Prefer direct dependencies when they are sufficient.
- Keep related data structures and operations close together.
- Introduce modules only when they establish a meaningful boundary.
- Do not create one module per function without a compelling reason.

Flatness does not mean putting everything in one file.

## 4. Small, Composable Components

Decompose functionality into the smallest *meaningful* components.

Each function, class, or module should:
- Have a single clear responsibility.
- Have a descriptive name that communicates its purpose.
- Expose a minimal, understandable interface.
- Avoid hidden state changes and implicit dependencies.
- Be independently understandable and testable where practical.

Do not split operations merely to minimize function length.
Each abstraction should reduce complexity, not redistribute it.

## 5. Explicit Data Flow

Prefer architectures where inputs, intermediate representations,
and outputs are visible.

- Make transformations explicit.
- Prefer passing required data over retrieving it from global state.
- Minimize mutable shared state.
- Make ownership and lifetime relationships understandable.
- Keep control flow predictable.
- Avoid unnecessary dependency injection and indirection.

A developer should be able to trace how data moves through the
system by reading the orchestration code.

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

# Code Styling

Architecture and code style work together. Clean structure buried
under noisy comments or compressed one-liners still fails the
readability test.

## 1. Comments Explain Why, Never What

- Do not write comments or docstrings that narrate what the code
  already says, restate types, or repeat README or PR prose.
- Avoid module-level essay docstrings, docstrings on
  self-explanatory internal functions, trailing `#` comments on
  struct or dataclass fields, and ASCII section banners
  (`# --- Helpers ---`).
- Keep comments only for non-obvious intent that names and types
  cannot express: external library quirks, domain formulas,
  invariants, or intentional workarounds.
- If a block needs a comment to explain what it does, extract a
  well-named variable or helper instead.

## 2. One Idea Per Line

- Write spacious, scannable code with descriptive local variables
  for intermediate steps and boolean conditions.
- Avoid compressed one-liners, nested comprehensions, chained
  ternaries, and single-letter abbreviations (`e`, `r`, `c`, `l`)
  for domain values.

Prefer:

```python
is_preposition = token.pos == PartOfSpeech.ADP
heads_phrase = token.dependency == Dependency.PREP
ends_before_target = token.right_edge == target_index - 1
return is_preposition and heads_phrase and ends_before_target
```

Over:

```python
# Check if token heads a PP ending right before target
return token.pos == PartOfSpeech.ADP and token.dependency == Dependency.PREP and token.right_edge == target_index - 1
```

## 3. Explicit Types Over Implicit Contracts

- Model structured data with frozen/immutable dataclasses, structs,
  or enums instead of repeating nested tuples
  (`list[tuple[str, list[Result]]]`) or untyped dicts.
- Avoid polymorphic return types that force callers into
  conditional `**kwargs`, `isinstance` checks, or magic-value
  branches (for example, inferring a formatting rule from
  `places == 4`). Handle variants explicitly inside one dedicated
  function or separate functions.
- Prefer typed fields and direct lookups over string-matching or
  scanning lists to infer metadata (such as checking whether a
  step was tuned or whether a row is the baseline).

## 4. Name Arguments When Their Roles Are Unclear

- Use keyword arguments for values whose role is unclear at the call site.
  Pay particular attention to literals and nearby arguments of the same type.
- Keep positional arguments when their names match the parameters or the call
  already makes their roles obvious, as in `compile(tokens)`.
- For positional-only APIs such as Python's `range`, give the values
  descriptive names or use an existing equivalent that accepts keywords.
  In code that already uses NumPy, `np.arange(start=5, stop=51, step=5)`
  makes the bounds and step visible. A short fixed sequence can be written out.

## 5. Match the Existing Codebase

When extending or refactoring an existing repository, match its
established conventions: entry-point layout, typing and
immutability defaults, spelling, naming style, and comment density.

# Refactoring Procedure

When asked to improve an existing codebase:

1. **Discover the architecture**
   - Identify the public entry points.
   - Trace the primary execution paths.
   - Identify important data structures and transformations.
   - Understand existing tests, invariants, performance constraints,
     and the repository's existing code style.

2. **Identify unnecessary complexity**
   - Excessive call depth.
   - Redundant forwarding functions.
   - Overly nested modules.
   - Unnecessary abstractions.
   - Hidden dependencies, implicit contracts, or mutable shared state.
   - Fragmented execution flow.
   - Comment bloat, compressed one-liners, and untyped data glue.

3. **Design the simplified architecture**
   - Sketch the ideal workflow as pseudocode.
   - Identify the smallest meaningful components.
   - Define explicit interfaces, typed models, and data flow.
   - Choose the simplest practical module hierarchy.
   - Compare the proposed architecture with the existing one.

4. **Implement the refactor**
   - Restructure code around the proposed execution flow.
   - Remove obsolete abstractions, unnecessary indirection, and
     comments that narrate the code.
   - Replace dense expressions with named intermediate values.
   - Preserve existing behavior and public APIs unless changes
     are explicitly authorized.
   - Avoid unrelated feature changes.

5. **Validate**
   - Run relevant tests and static checks.
   - Check for performance regressions where applicable.
   - Confirm that the main execution flow is easier to follow.
   - Review whether each remaining abstraction and comment is
     justified.

# Expected Result

The resulting codebase should have:

- An entry point that reads like a high-level algorithm.
- A clear, mostly linear execution pipeline.
- A shallow and meaningful module hierarchy.
- Small, cohesive, well-named components with one idea per line.
- Explicit typed models, dependencies, and data transformations.
- Minimal unnecessary indirection and minimal comments (why only).
- Consistent style with the surrounding repository.
- Preserved functionality and performance characteristics.

When explaining architectural changes, show the proposed
high-level pseudocode, module structure, and data flow.

**The ultimate measure of success is how quickly a developer
can understand the system, not how few functions or files it has.**
