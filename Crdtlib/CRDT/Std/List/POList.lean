module

public import Crdtlib.CRDT.Primitive.ACFun
public import Crdtlib.CRDT.Std.Set.GSet
public import Crdtlib.CRDT.Std.Set.PNSet
public import Crdtlib.Combinator.Principal.Associate
public import Crdtlib.Combinator.Derived.MapOp
public import Crdtlib.Combinator.Derived.JointProduct
public import Crdtlib.Combinator.Principal.MapInterpretation
public import Crdtlib.Combinator.Principal.Traverse
public import Crdtlib.Combinator.Derived.DisjointProduct
public import Crdtlib.Combinator.Principal.MapState
public import Batteries

@[expose] public section

section POList

open Batteries

instance : Zero (Finset α) where
  zero := ∅

def po_traversal {σ : Type*}
    [DecidableEq σ] [LinearOrder σ] [Bot σ] [Hashable σ]
    (s : SetInterp σ × AssociateInterp σ (SetInterp σ))
    : List σ :=
  let ⟨live, adj⟩ := s
  let succs : σ → List σ := λ v ↦ (adj.map v).toList.reverse
  let bound : ℕ := 1 + adj.toList.foldl (λ n kv ↦ n + kv.snd.toList.length) 0
  let rec go (fuel : ℕ) (visited out : List σ) (v : σ) : List σ × List σ :=
    match fuel with
    | 0 => (visited, out)
    | fuel + 1 =>
      let (visited', out') :=
        (succs v).foldl
          (λ acc w ↦
            if acc.fst.contains w then acc
            else go fuel (w :: acc.fst) acc.snd w)
          (visited, out)
      (visited', if live.mem v ∧ v ≠ ⊥ then v :: out' else out')
  (go bound [⊥] [] ⊥).snd

-- ANCHOR: list_op
inductive ListOp (σ : Type*) where
  | insert (prev : σ) (elem : σ) (next : σ)
  | remove (elem : σ)
-- ANCHOR_END: list_op

variable (σ : Type*) [Hashable σ] [DecidableEq σ] [Zero σ]

-- ANCHOR: pol_ops
structure POL.Insert where
  prev : σ
  elem : σ
  next : σ

structure POL.Remove where
  elem : σ
-- ANCHOR_END: pol_ops

-- ANCHOR: po_edges
def edges : CRDT (σ × σ) (Associate σ (GSet σ)) (AssociateInterp σ (SetInterp σ)) :=
  associate σ (gset σ)

def po_edges : CRDT (σ × σ × σ) (Associate σ (GSet σ)) (AssociateInterp σ (SetInterp σ)) :=
  traverse (λ ⟨prev, elem, next⟩ ↦ [⟨prev, elem⟩, ⟨elem, next⟩]) (edges σ)
-- ANCHOR_END: po_edges

abbrev POListState := (Associate σ ℤ) × (Associate σ (GSet σ))

instance : DecidableEq (POListState σ) := inferInstance

-- ANCHOR: polist
def polist [LinearOrder σ] [Bot σ] : CRDT (ListOp σ) (POListState σ) (List σ) :=
  map_interpretation po_traversal
    $ traverse (λ
        | .insert prev elem next => [.inl $ .add elem, .inr ⟨prev, elem, next⟩]
        | .remove elem => [.inl $ .remove elem])
    $ (disjoint_product
        -- add-nodes, edges
        (pnset σ)
        (po_edges σ))
-- ANCHOR_END: polist

def polistₜ {τ : Type} [PartialOrder τ] [LinearOrder σ] [Bot σ] :
    CRDTₜ τ (ListOp σ) (POListState σ) (List σ) :=
  (polist σ).toCRDTₜ τ

def POL.po_traversal {σ : Type*}
    [DecidableEq σ] [LinearOrder σ] [Bot σ] [Hashable σ]
    (s : (SetInterp σ × AssociateInterp σ (SetInterp σ)) × SetInterp σ) : List σ :=
  let ⟨⟨add, adj⟩, rem⟩ := s
  let live : σ → Bool := λ v ↦ add.mem v && !(rem.mem v)
  let succs : σ → List σ := λ v ↦ (adj.map v).toList.reverse
  let bound : ℕ := 1 + adj.toList.foldl (λ n kv ↦ n + kv.snd.toList.length) 0
  let rec go (fuel : ℕ) (visited out : List σ) (v : σ) : List σ × List σ :=
    match fuel with
    | 0 => (visited, out)
    | fuel + 1 =>
      let (visited', out') :=
        (succs v).foldl
          (λ acc w ↦
            if acc.fst.contains w then acc
            else go fuel (w :: acc.fst) acc.snd w)
          (visited, out)
      (visited', if live v ∧ v ≠ ⊥ then v :: out' else out')
  (go bound [⊥] [] ⊥).snd

-- We use the PNSet (the other) version for automerge because it is more efficient
-- ANCHOR: pol_polist
def POL.polist [LinearOrder σ] [Bot σ] :
    CRDT (Insert σ ⊕ Remove σ) ((GSet σ × Associate σ (GSet σ)) × (GSet σ)) (List σ) :=
  map_interpretation po_traversal
    (disjoint_product
      (map_op (λ ⟨p, v, n⟩ ↦ ⟨v, ⟨p, v, n⟩⟩) (joint_product (gset σ) (po_edges σ)))
      (map_op (λ ⟨o⟩ ↦ o) (gset σ)))
-- ANCHOR_END: pol_polist

end POList

section POListWithValues

open ListOp

inductive ValueListOp (χ ω : Type*) where
  | mutate (pos : χ) (op : ω)
  | insert (prev : χ) (pos : χ) (next : χ)
  | remove (elem : χ)

variable (χ : Type u) [DecidableEq χ]

-- ANCHOR: polist_with_values
def polist_with_values [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [DecidableEq σ] (c : CRDT ω σ γ) :
    CRDT (ValueListOp χ ω) (Associate χ σ × POListState χ) (List (χ × γ)) := id
  <| map_interpretation (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
  <| map_op (λ
    | .mutate pos op => .inl ⟨pos, op⟩
    | .insert prev pos next => .inr $ .insert prev pos next
    | .remove pos => .inr $ .remove pos)
  <| disjoint_product (associate χ c) (polist χ)
-- ANCHOR_END: polist_with_values

def polist_with_valuesₜ [PartialOrder τ] [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [DecidableEq σ] (c : CRDTₜ τ ω σ γ) :
    CRDTₜ τ (ValueListOp χ ω) (Associate χ σ × POListState χ) (List (χ × γ)) := id
  <| map_interpretationₜ (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
  <| map_opₜ (λ
    | .mutate pos op => .inl ⟨pos, op⟩
    | .insert prev pos next => .inr $ .insert prev pos next
    | .remove pos => .inr $ .remove pos)
  <| disjoint_productₜ (associateₜ χ c) (polistₜ χ)

end POListWithValues
