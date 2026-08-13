import Crdtlib.CRDT.Primitive.ACFun
import Crdtlib.CRDT.Std.Set.GSet
import Crdtlib.CRDT.Std.Set.PNSet
import Crdtlib.Combinator.Principal.Associate
import Crdtlib.Combinator.Derived.MapOp
import Crdtlib.Combinator.Derived.JointProduct
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Principal.Traverse
import Crdtlib.Combinator.Derived.DisjointProduct
import Crdtlib.Combinator.Principal.MapState
import Batteries

section POList

open Batteries

instance : Zero (Finset α) where
  zero := ∅

private def po_traversal {σ : Type*}
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

inductive ListOp (σ : Type*) where
  | insert (prev : σ) (elem : σ) (next : σ)
  | remove (elem : σ)

variable (σ : Type*) [Hashable σ] [DecidableEq σ] [Zero σ]

structure POL.Insert where
  prev : σ
  elem : σ
  next : σ

structure POL.Delete where
  elem : σ

def edges
  : CRDT (POL.Insert σ) (Associate σ (GSet σ)) (AssociateInterp σ (SetInterp σ))
  := traverse
    (λ ⟨prev, elem, next⟩ ↦ [⟨prev, elem⟩, ⟨elem, next⟩])
    (associate σ (gset σ))

-- def edges'
--   : CRDT (σ × σ × σ) (Std.ExtHashMap σ (Std.ExtHashMap σ Bool)) (σ → (Std.ExtHashMap σ Bool))
--   := edges σ

abbrev POListState := (Associate σ ℤ) × (Associate σ (GSet σ))

instance : DecidableEq (POListState σ) := inferInstance

def polist [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
  : CRDT (ListOp σ) (POListState σ) (List σ)
  := map_interpretation po_traversal
    $ traverse
      (λ op ↦ match op with
        | .insert prev elem next => [.inl $ .add elem, .inr ⟨prev, elem, next⟩]
        | .remove elem => [.inl $ .remove elem]
      )
    $ (disjoint_product
        -- add-nodes, edges
        (pnset σ)
        (edges σ))

def polistₜ {τ : Type} [PartialOrder τ] [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
  : CRDTₜ τ (ListOp σ) (POListState σ) (List σ)
  := (polist σ).toCRDTₜ τ

private def POL.po_traversal {σ : Type*}
    [DecidableEq σ] [LinearOrder σ] [Bot σ] [Hashable σ]
    (s : (SetInterp σ × AssociateInterp σ (SetInterp σ)) × SetInterp σ)
    : List σ :=
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
def POL.list [LinearOrder σ] [Bot σ] [Hashable σ]
  : CRDT (Insert σ ⊕ Delete σ) ((GSet σ × Associate σ (GSet σ)) × (GSet σ)) (List σ)
  := map_interpretation POL.po_traversal
    (disjoint_product
      (map_op (λ ⟨p, v, n⟩ ↦ ⟨v, ⟨p, v, n⟩⟩) (joint_product (gset σ) (edges σ)))
      (map_op (λ ⟨o⟩ ↦ o) (gset σ)))

end POList

section POListWithValues

open ListOp

inductive ValueListOp (χ ω : Type*) where
  | mutate (pos : χ) (op : ω)
  | insert (prev : χ) (pos : χ) (next : χ)
  | remove (elem : χ)

variable (χ : Type u) [DecidableEq χ]

def polist_with_values [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [DecidableEq σ] (c : CRDT ω σ γ)
  : CRDT (ValueListOp χ ω) (Associate χ σ × POListState χ) (List (χ × γ))
  := id
    $ map_interpretation (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
    $ map_op (λ op ↦ match op with
      | .mutate pos op => .inl ⟨pos, op⟩
      | .insert prev pos next => .inr $ .insert prev pos next
      | .remove pos => .inr $ .remove pos)
    $ disjoint_product (associate χ c) (polist χ)

def polist_with_valuesₜ [PartialOrder τ] [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [DecidableEq σ] (c : CRDTₜ τ ω σ γ)
  : CRDTₜ τ (ValueListOp χ ω) (Associate χ σ × POListState χ) (List (χ × γ))
  := id
    $ map_interpretationₜ (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
    $ map_opₜ (λ op ↦ match op with
      | .mutate pos op => .inl ⟨pos, op⟩
      | .insert prev pos next => .inr $ .insert prev pos next
      | .remove pos => .inr $ .remove pos)
    $ disjoint_productₜ (associateₜ χ c) (polistₜ χ)

end POListWithValues
