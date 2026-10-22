module

public import VersoBlog

@[expose] public section

open Verso.Genre.Blog (Page)
open Verso.Code.External

set_option verso.exampleProject "."

#doc (Page) "Get started" =>

This guide show how to add crdtlib to a Lean project and build a simple CRDT.
The examples live in `Examples/GettingStarted.lean` in the repository.

# Add the dependency

crdtlib is a Lake package. Add it to your `lakefile.lean`:

```
require crdtlib from git "https://github.com/prg-grp/crdtlib" @ "master"
```

or, if you use `lakefile.toml`:

```
[[require]]
name = "crdtlib"
git = "https://github.com/prg-grp/crdtlib"
rev = "master"
```

The library uses Mathlib and Lean `v4.35.0`, so use the same toolchain in your `lean-toolchain`.

# Compose a CRDT

A task has a set of tags and a priority.
Crdtlib comes with standard CRDTs such as grow-only set and counter, which we can reuse here.
`disjoint_product` puts them side by side, and `map_op` gives the constructed CRDT a semantically significant operation type.

```anchor compose (module := Examples.GettingStarted)
/-- Operations on a task: tag it, or adjust its priority. -/
inductive TaskOp
  | tag (label : String)
  | bump (priority : Int)

/-- A replicated task: a grow-only set of tags next to a priority counter. -/
def task : CRDT TaskOp (GSet String × Int) (SetInterp String × Int) :=
  map_op (λ | .tag l => .inl l | .bump n => .inr n)
    (disjoint_product (gset String) counter)
```

The operations are `TaskOp`s, the state is a `GSet` next to an integer, and readers see a set next to a number.

# Watch it converge

Applying the same operations in either order gives the same task. `#guard` checks this when the file is compiled.

```anchor run (module := Examples.GettingStarted)
/-- Two replicas receive the same operations in different orders… -/
def replicaA := task.effect (.bump 2) (task.effect (.tag "urgent") 0)
def replicaB := task.effect (.tag "urgent") (task.effect (.bump 2) 0)

-- …and observe the same task.
#guard (task.interpret replicaA).1.mem "urgent" && (task.interpret replicaB).1.mem "urgent"
#guard (task.interpret replicaA).2 == (task.interpret replicaB).2
```

# Get the proof for free

The `commutative` field is built by the combianators.

```anchor free (module := Examples.GettingStarted)
/-- No new proof needed: commutativity comes with the composite. -/
example (a b : TaskOp) : task.effect b ∘ task.effect a = task.effect a ∘ task.effect b :=
  task.commutative a b
```

# Write your own primitive

When no building block fits, write the three fields yourself and prove `commutative` once.
From then on, every combinator accepts your CRDT.

```anchor primitive (module := Examples.GettingStarted)
/-- A primitive CRDT written by hand: replicas keep the largest value seen. -/
def high_score : CRDT Nat Nat Nat where
  effect := max
  interpret := id
  commutative a b := by
    funext s
    exact max_left_comm b a s
```

If your CRDT needs to tell concurrent operations apart, use `CRDTₜ` instead. The [model](/docs/model/#crdts-without-timestamps) explains the difference.
