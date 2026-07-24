
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.MapOp
import Crdtlib.Combinator.Derived.DisjointProduct
import Crdtlib.CRDT.Std.Set.GSet
import Mathlib.Data.Finset.Basic

def lww_element_set [PartialOrder τ] (σ : Type) [DecidableEq τ] [DecidableEq σ] [DecidableLT τ]
  : CRDT (SetOp (Event τ σ)) (Finset (Event τ σ) × Finset (Event τ σ)) (Finset σ)
  := map_interpretation (λ ⟨addSet, removeSet⟩ ↦
      (addSet.filter (λ a ↦ ¬ (removeSet.filter (λ r ↦ r.v = a.v ∧ a.t < r.t)).Nonempty)).image (·.v))
    (map_op (λ | .add elem => .inl {elem} | .remove elem => .inr {elem})
      (disjoint_product (union_set (Event τ σ)) (union_set (Event τ σ))))
