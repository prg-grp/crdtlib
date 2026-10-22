module

public import VersoBlog
public import Shared.Cards

@[expose] public section

open Verso.Genre.Blog (Page)
open Verso.Code.External

set_option verso.exampleProject "."

#doc (Page) "Catalog" =>

Standard CRDTs from Shapiro et al.'s catalog, assembled from crdtlib's combinators.

:::Shared.recipeLegend
:::

# Primitives

Primitive CRDTs are not built from other CRDTs. They come in two families, and both use the identity as their interpretation.

## AC functions

Any associative and commutative function is a CRDT: the state is a value, and each operation is merged into it. This is a relaxation of a state-based CRDT's merge, which must also be idempotent. Counters, grow-only counters, maxima of a join-semilattice and set unions are all instances.

```anchor ac_fun (module := Crdtlib.CRDT.Primitive.ACFun)
def ac_fun (α : Type u) (f : α → α → α) [c : Std.Commutative f] [a : Std.Associative f] :
    CRDT α α α where
  effect := f
  interpret := id
  commutative e₁ e₂ := by
    ext s
    simp
    rw [←a.assoc e₁ e₂, c.comm e₁ e₂, ←a.assoc e₂ e₁]
```

```anchor ac_instances (module := Crdtlib.CRDT.Primitive.ACFun)
def counter : CRDT Int Int Int := ac_fun Int (· + ·)
def gcounter : CRDT Nat Nat Nat := ac_fun Nat (· + ·)

def join (σ : Type) [SemilatticeSup σ] : CRDT σ σ σ := ac_fun σ max

-- examples of join

def union_set (σ : Type) [DecidableEq σ] := join (Finset σ)
def max_int := join Int
```

## MV Register

:::Shared.recipe "MV Register"
:::

Keeps every write that has not been overwritten by a causally later one: a new write removes the writes with strictly smaller timestamps, but not concurrent ones. It needs timestamps, so it is a `CRDTₜ`. An associative, commutative merge has no notion of timestamps, so this family cannot be reduced to the first one.

```anchor mv_reg (module := Crdtlib.CRDT.Primitive.MVReg)
def mv_regₜ (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [LinearOrder σ] :
    CRDTₜ τ σ (Finset (Event τ σ)) (Finset (Event τ σ)) where
  effect e s :=
    -- unfortunately this does not improve the complexity because the filter must go through all elements in the worst case
    -- the maximum number of elements in the set is equal to the number of replicas in the network
    -- insert e (Std.HashSet.filter (λ x ↦ ¬ x.t < e.t) s)
    insert e (s.filter λ x ↦ ¬ x.t < e.t)
  interpret := id
```

# Registers

## LWW Register

:::Shared.recipe "LWW Register"
:::

Values tagged with a Lamport time, ordered by time and then by value. Since the order is total, it is a join-semilattice, and keeping the maximum means the last write wins, with ties broken the same way everywhere.

```anchor lww (module := Crdtlib.CRDT.Std.LWW.LWW)
structure Lamport (σ : Type) where (t : Nat) (s : σ)

instance [LinearOrder σ] : LinearOrder (Lamport σ) :=
  LinearOrder.lift'
    (λ x => toLex (x.t, x.s))
    (λ a b h => by obtain ⟨ta, sa⟩ := a; obtain ⟨tb, sb⟩ := b; simpa using h)

def lww (σ : Type) [LinearOrder σ] : CRDT (Lamport σ) (Lamport σ) (Lamport σ) := join (Lamport σ)
```

## MV-LWW Register

:::Shared.recipe "MV-LWW Register"
:::

A last-writer-wins register for when timestamps are only partially ordered. Concurrent writes cannot be resolved on arrival, so the state is that of a multi-value register, and the tie is broken when the register is read, by picking the largest value.

```anchor mv_lww (module := Crdtlib.CRDT.Std.LWW.MVLWW)
def mv_lwwₜ (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [LinearOrder σ] [Zero σ] :
    CRDTₜ τ σ (Finset (Event τ σ)) σ :=
  map_interpretationₜ (λ s ↦
      match (s.image (·.o)).max with
        | .none => 0
        | .some x => x
    ) (mv_regₜ σ)
```

# Sets

## G-Set

:::Shared.recipe "G-Set"
:::

A grow-only set. It counts how often each element was added, using `associate` over grow-only counters, and shows the elements with a positive count.

```anchor gset (module := Crdtlib.CRDT.Std.Set.GSet)
abbrev GSet (σ : Type*) [Hashable σ] [DecidableEq σ] := Associate σ ℕ

instance (σ : Type*) [Hashable σ] [DecidableEq σ] : Zero $ GSet σ where
  zero := Std.ExtHashMap.emptyWithCapacity 8

def gset (σ : Type*) [Hashable σ] [DecidableEq σ] : CRDT σ (GSet σ) (SetInterp σ) :=
  map_interpretation
    (λ s ↦ { mem := (· > 0) ∘ s.map, toList := s.toList.filterMap λ ⟨k, v⟩ ↦ if v > 0 then .some k else .none })
    (map_op (λ x ↦ ⟨x, 1⟩)
      (associate σ gcounter))
```

## 2P-Set

:::Shared.recipe "2P-Set"
:::

A live set and a tombstone set, both grow-only. An element is present if it is in the live set but not in the tombstone set, so once removed, it can never be added again.

```anchor tpset (module := Crdtlib.CRDT.Std.Set.TPSet)
def tpset (σ : Type*) [DecidableEq σ] [Hashable σ] : CRDT (SetOp σ) (GSet σ × GSet σ) (SetInterp σ) :=
  map_interpretation (λ ⟨addSet, removeSet⟩ ↦ {
      mem k := addSet.mem k ∧ ¬ removeSet.mem k, toList := addSet.toList.filter (¬ removeSet.mem ·) })
    (map_op (λ
        | .add    elem => .inl elem
        | .remove elem => .inr elem)
      (disjoint_product (gset σ) (gset σ)))
```

## LWW-Element Set

:::Shared.recipe "LWW-Element Set"
:::

Adds and removes are timestamped events, kept in two G-Sets. An element is present if one of its adds has no strictly later remove. When an add and a remove of the same element are concurrent, neither is later, so the add wins.

```anchor lww_element_set (module := Crdtlib.CRDT.Std.Set.LWWSet)
def lww_element_set (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [Hashable τ]
    [DecidableEq σ] [Hashable σ] [LinearOrder (Event τ σ)] :
    CRDT (SetOp (Event τ σ)) (GSet (Event τ σ) × GSet (Event τ σ)) (SetInterp σ) :=
  map_interpretation (λ ⟨addSet, removeSet⟩ ↦
      let removes := removeSet.toList
      let live := addSet.toList.filter (λ a ↦ ¬ removes.any (λ r ↦ r.o == a.o ∧ (a.t < r.t)))
      { mem s := live.any (λ a ↦ a.o == s), toList := (live.map (·.o)).dedup })
    (map_op (λ | .add elem => .inl elem | .remove elem => .inr elem)
      (disjoint_product (gset (Event τ σ)) (gset (Event τ σ))))
```

## PN-Set

:::Shared.recipe "PN-Set"
:::

A counter per element instead of a tombstone: `add` counts up, `remove` counts down, and an element is present while its count is positive.

```anchor pnset (module := Crdtlib.CRDT.Std.Set.PNSet)
def pnset (σ : Type*) [DecidableEq σ] [Hashable σ] : CRDT (SetOp σ) (Associate σ Int) (SetInterp σ) :=
  map_interpretation (λ s ↦ {
      mem := (· > (0 : ℤ)) ∘ s.map,
      toList := s.toList.filterMap λ ⟨k, v⟩ ↦ if v > 0 then .some k else .none })
    (map_op (λ | .add elem => ⟨elem, 1⟩ | .remove elem => ⟨elem, -1⟩)
      (associate σ counter))
```

## OR-Set

:::Shared.recipe "OR-Set"
:::

Every add tags its element with a unique token. A remove names the tagged pairs its replica has seen, so it only cancels adds that causally precede it, and a concurrent add survives. Structurally, it is a 2P-Set over tagged elements.

```anchor orset (module := Crdtlib.CRDT.Std.Set.ORSet)
inductive OROp (σ tok : Type) where
  | add (elem : σ) (token : tok)
  | remove (observed : Finset (σ × tok))

def orset (σ tok : Type) [DecidableEq σ] [DecidableEq tok] :
    CRDT (OROp σ tok) (Finset (σ × tok) × Finset (σ × tok)) (Finset σ) :=
  map_interpretation (λ ⟨addSet, tombstone⟩ ↦ (addSet \ tombstone).image Prod.fst)
    (map_op (λ | .add elem token => .inl {(elem, token)} | .remove observed => .inr observed)
      (disjoint_product (union_set (σ × tok)) (union_set (σ × tok))))
```

# Sequences

## List

:::Shared.recipe "List"
:::

The paper's running example, the _add-remove partial order_. Inserting `elem` between `prev` and `next` adds the element to a set of nodes and two edges to a graph; removing it adds it to a tombstone set. The list is read by a traversal from `⊥` that emits a node once all its predecessors have been visited, and uses the order on elements to break ties between concurrent insertions at the same place.

```anchor pol_ops (module := Crdtlib.CRDT.Std.List.POList)
structure POL.Insert where
  prev : σ
  elem : σ
  next : σ

structure POL.Remove where
  elem : σ
```

```anchor pol_polist (module := Crdtlib.CRDT.Std.List.POList)
def POL.polist [LinearOrder σ] [Bot σ] :
    CRDT (Insert σ ⊕ Remove σ) ((GSet σ × Associate σ (GSet σ)) × (GSet σ)) (List σ) :=
  map_interpretation po_traversal
    (disjoint_product
      (map_op (λ ⟨p, v, n⟩ ↦ ⟨v, ⟨p, v, n⟩⟩) (joint_product (gset σ) (po_edges σ)))
      (map_op (λ ⟨o⟩ ↦ o) (gset σ)))
```

The edges come from [`po_edges`](/docs/combinators/#traverse). The library also has `polist`, which tracks nodes with a PN-Set instead of a node set and a tombstone set. It allocates no separate tombstone set, and the JSON tree in the paper uses it.

```anchor list_op (module := Crdtlib.CRDT.Std.List.POList)
inductive ListOp (σ : Type*) where
  | insert (prev : σ) (elem : σ) (next : σ)
  | remove (elem : σ)
```

```anchor polist (module := Crdtlib.CRDT.Std.List.POList)
def polist [LinearOrder σ] [Bot σ] : CRDT (ListOp σ) (POListState σ) (List σ) :=
  map_interpretation po_traversal
    $ traverse (λ
        | .insert prev elem next => [.inl $ .add elem, .inr ⟨prev, elem, next⟩]
        | .remove elem => [.inl $ .remove elem])
    $ (disjoint_product
        -- add-nodes, edges
        (pnset σ)
        (po_edges σ))
```

## List with Values

:::Shared.recipe "List with Values"
:::

Pairs each position in the list with a value from any CRDT `c`, kept by `associate`, so entries can be edited in place. The collaborative game in the paper uses it for a threaded chat, with an MV-LWW register of strings at each position.

```anchor polist_with_values (module := Crdtlib.CRDT.Std.List.POList)
def polist_with_values [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [DecidableEq σ] (c : CRDT ω σ γ) :
    CRDT (ValueListOp χ ω) (Associate χ σ × POListState χ) (List (χ × γ)) := id
  <| map_interpretation (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
  <| map_op (λ
    | .mutate pos op => .inl ⟨pos, op⟩
    | .insert prev pos next => .inr $ .insert prev pos next
    | .remove pos => .inr $ .remove pos)
  <| disjoint_product (associate χ c) (polist χ)
```

# Combinator usage

Which combinators each construction uses, directly or through another combinator.

:::Shared.usageMatrix
:::
