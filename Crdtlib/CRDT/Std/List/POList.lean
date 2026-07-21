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
    (s : SetInterpretation σ × AssociateInterpretation σ (SetInterpretation σ))
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

def edges
  : CRDT (σ × σ × σ) (Associate σ (GSet σ)) (AssociateInterpretation σ (SetInterpretation σ))
  := traverse
    (λ ⟨prev, elem, next⟩ ↦ [⟨prev, elem⟩, ⟨elem, next⟩])
    (associate σ (gset σ))

-- def edges'
--   : CRDT (σ × σ × σ) (Std.ExtHashMap σ (Std.ExtHashMap σ Bool)) (σ → (Std.ExtHashMap σ Bool))
--   := edges σ


abbrev POListState := (Associate σ ℤ) × (Associate σ (GSet σ))

instance : DecidableEq (POListState σ) := inferInstance

def po_list [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
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

def po_listₜ {τ : Type} [PartialOrder τ] [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
  : CRDTₜ τ (ListOp σ) (POListState σ) (List σ)
  := (po_list σ).toCRDTₜ τ

end POList

section POListWithValues

open ListOp

inductive ValueListOp (χ ω : Type*) where
  | mutate (pos : χ) (op : ω)
  | insert (prev : χ) (pos : χ) (next : χ)
  | remove (elem : χ)

variable (χ : Type u) [DecidableEq χ]

def po_list_with_values [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [DecidableEq σ] (c : CRDT ω σ γ)
  : CRDT (ValueListOp χ ω) (Associate χ σ × POListState χ) (List (χ × γ))
  := id
    $ map_interpretation (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
    $ map_op (λ op ↦ match op with
      | .mutate pos op => .inl ⟨pos, op⟩
      | .insert prev pos next => .inr $ .insert prev pos next
      | .remove pos => .inr $ .remove pos)
    $ disjoint_product (associate χ c) (po_list χ)

def po_list_with_valuesₜ [PartialOrder τ] [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [DecidableEq σ] (c : CRDTₜ τ ω σ γ)
  : CRDTₜ τ (ValueListOp χ ω) (Associate χ σ × POListState χ) (List (χ × γ))
  := id
    $ map_interpretationₜ (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
    $ map_opₜ (λ op ↦ match op with
      | .mutate pos op => .inl ⟨pos, op⟩
      | .insert prev pos next => .inr $ .insert prev pos next
      | .remove pos => .inr $ .remove pos)
    $ disjoint_productₜ (associateₜ χ c) (po_listₜ χ)

end POListWithValues
