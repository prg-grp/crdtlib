import Crdtlib.CRDT.Primitive.ACFun
import Crdtlib.CRDT.Std.Set.GHashSet
import Crdtlib.CRDT.Std.Set.PNSet
import Crdtlib.Combinator.Principal.Associate
import Crdtlib.Combinator.Derived.MapOp
import Crdtlib.Combinator.Derived.JointProduct
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Principal.Traverse
import Crdtlib.Combinator.Derived.DisjointProduct
import Batteries

section POList

open Batteries

instance : Zero (Finset α) where
  zero := ∅

private def po_traversal {σ : Type*}
    [DecidableEq σ] [LinearOrder σ] [Bot σ] [Hashable σ]
    (s : SetInterpretation σ × AssociateInterpretation σ (SetInterpretation σ))
    : List σ :=
      [] -- TODO (only for interpretation, not used in benchmarks)

inductive ListOp (σ : Type*) where
  | insert (prev : σ) (elem : σ) (next : σ)
  | remove (elem : σ)

variable (σ : Type*) [Hashable σ] [DecidableEq σ] [Zero σ]

def edges [Hashable σ]
  : CRDT' (σ × σ × σ) (AssociateState σ (GHashSetState σ)) (AssociateInterpretation σ (SetInterpretation σ))
  := traverse'
    (λ ⟨prev, elem, next⟩ ↦ [⟨prev, elem⟩, ⟨elem, next⟩])
    (associate' σ (ghashset' σ))

abbrev POListState [DecidableEq σ] [Hashable σ]
  := (AssociateState σ ℤ) × (AssociateState σ (GHashSetState σ))

def po_list' [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
  : CRDT' (ListOp σ) (POListState σ) (List σ)
  := map_interpretation' po_traversal
    $ traverse'
      (λ op ↦ match op with
        | .insert prev elem next => [.inl $ .add elem, .inr ⟨prev, elem, next⟩]
        | .remove elem => [.inl $ .remove elem]
      )
    $ (disjoint_product'
        -- add-nodes, edges
        (pnset' σ)
        (edges σ))

def po_list {τ : Type} [PartialOrder τ] [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
  : CRDT τ (ListOp σ) (POListState σ) (List σ)
  := (po_list' σ).toCRDT τ

end POList

section POListWithValues

open ListOp

inductive ValueListOp (χ ω : Type*) where
  | mutate (pos : χ) (op : ω)
  | insert (prev : χ) (pos : χ) (next : χ)
  | remove (elem : χ)

variable (χ : Type u) [DecidableEq χ]

def po_list_with_values {τ : Type} [PartialOrder τ] [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [Zero γ]
  (c : CRDT τ ω σ γ)
  : CRDT τ (ValueListOp χ ω) (AssociateState χ σ × POListState χ) (List (χ × γ))
  := id
    $ map_interpretation (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
    $ map_op (λ op ↦ match op with
      | .mutate pos op => .inl ⟨pos, op⟩
      | .insert prev pos next => .inr $ .insert prev pos next
      | .remove pos => .inr $ .remove pos)
    $ disjoint_product (associate χ c) (po_list χ)

end POListWithValues
