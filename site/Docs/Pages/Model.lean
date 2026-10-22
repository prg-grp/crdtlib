import VersoBlog

import Shared.Layout

open Verso.Genre.Blog (Page)
open Verso.Code.External

set_option verso.exampleProject "."

#doc (Page) "The model" =>

crdtlib works with _operation-based_ CRDTs. This page describes the system they run in, what a CRDT is in the library, and why the one property it asks for is enough for replicas to agree, even when CRDTs are composed.

# The system

Each replica is a node in an asynchronous network and holds a copy of the state. The network is assumed to provide three delivery guarantees:

* *Causal order.* A message is not received before all of its causal predecessors.
* *Eventual delivery.* Every message delivered to one replica is eventually delivered to all of them.
* *Exactly once.* Every message is delivered to each replica once, so an event takes effect at most once per replica.

We assume no Byzantine faults, and all replicas start from the same initial state.

On every replica, a small runtime connects the application, the network and the CRDT. When the application issues an operation, the runtime advances the local timestamp, packages the two into an _event_, applies the event to the local state, and broadcasts it. When an event arrives from another replica, the runtime merges its timestamp and applies it in the same way. After every change, the runtime _interprets_ the new state and hands the result to the application.

# Strong eventual consistency

The guarantee that CRDTs provide is _strong eventual consistency_.
Replicas that have received the same updates have equivalent states.
Operation-based CRDTs achieve this without coordination: under the delivery guarantees above, it is enough that the effects of concurrent events commute.

# Events and concurrency

An event pairs an operation with a partially ordered logical timestamp.
Two events are concurrent when neither timestamp is ordered compared to the other.

```anchor Event (module := Crdtlib.CRDT.Pkg)
structure Pkg (τ : Type) (υ : Type u) where
  t : τ
  v : υ
deriving DecidableEq

@[simp, reducible]
def Event := Pkg

@[simp, reducible]
def Event.o (e : Event τ υ) := e.v
```

```anchor Concurrent (module := Crdtlib.CRDT.Concurrent)
structure Concurrent {τ : Type} [LE τ] (t₁ t₂ : τ) : Prop where
  concurrent : ¬ (t₁ ≤ t₂) ∧ ¬ (t₂ ≤ t₁)
```

# The CRDT structure

```anchor CRDTt (module := Crdtlib.CRDT.Basic)
structure CRDTₜ (τ : Type) [PartialOrder τ] (ω σ γ : Type*) where
  effect : Event τ ω → σ → σ
  interpret : σ → γ
  commutative : ∀ (e₁ e₂ : Event τ ω),
    Concurrent e₁.t e₂.t → (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂)
```

The type parameters:

* `τ` is the type of timestamps, ordered by causality.
* `ω` is the type of operations, which replicas send to each other.
* `σ` is the type of states, which each replica stores.
* `γ` is the type of interpreted states, which the application observes.

The fields:

* `effect` applies an event to the state.
* `interpret` turns the state into an interpreted state. It can differ from the state: a register may store every concurrent write but show only one.
* `commutative` requires the effects of any two concurrent events to commute.

Because `commutative` is a field, a value of this type _is_ a proof that its effects commute. There is no separate correctness theorem to state or to forget.

# Why commutativity is enough

Take two replicas that have delivered the same events. Causal delivery means that both applied causally related events in the same relative order, so their delivery orders can differ only in how concurrent events are interleaved. One order can be turned into the other by repeatedly swapping adjacent events, and each swap exchanges two concurrent events. By `commutative`, no swap changes the state. Both replicas hold the same state, and the application sees the same interpreted state.

# CRDTs without timestamps

Many CRDTs never look at timestamps, because their effects commute whatever the order. For those, the library has a simpler structure, in which `commutative` must hold for every pair of operations.

```anchor CRDT (module := Crdtlib.CRDT.Basic)
structure CRDT (ω σ γ : Type*) where
  effect : ω → σ → σ
  interpret : σ → γ
  commutative : ∀ (e₁ e₂ : ω),
    (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂)
```

This is the stronger promise, so any such CRDT is also a timestamped one: `toCRDTₜ` ignores the timestamps. By convention, CRDTs and combinators with a `ₜ` suffix work with `CRDTₜ`, and those without work with `CRDT`.

```anchor toCRDTt (module := Crdtlib.CRDT.Basic)
def CRDT.toCRDTₜ (τ : Type) [PartialOrder τ] (c : CRDT ω σ γ) : CRDTₜ τ ω σ γ where
  effect e := c.effect e.o
  interpret := c.interpret
  commutative e₁ e₂ _ := c.commutative e₁.o e₂.o
```

Timestamps matter to CRDTs that resolve concurrent writes, such as the [multi-value register](/docs/catalog/#mv-register) and the [tagged union](/docs/combinators/#taggedunion).
