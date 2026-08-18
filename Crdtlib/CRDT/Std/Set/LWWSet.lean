
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.MapOp
import Crdtlib.Combinator.Derived.DisjointProduct
import Crdtlib.CRDT.Std.Set.GSet
import Mathlib.Data.Finset.Basic

def lww_element_set (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [Hashable τ]
    [DecidableEq σ] [Hashable σ] [LinearOrder (Event τ σ)] :
    CRDT (SetOp (Event τ σ)) (GSet (Event τ σ) × GSet (Event τ σ)) (SetInterp σ) :=
  map_interpretation (λ ⟨addSet, removeSet⟩ ↦
      let removes := removeSet.toList
      let live := addSet.toList.filter (λ a ↦ ¬ removes.any (λ r ↦ r.o == a.o ∧ (a.t < r.t)))
      { mem s := live.any (λ a ↦ a.o == s), toList := (live.map (·.o)).dedup })
    (map_op (λ | .add elem => .inl elem | .remove elem => .inr elem)
      (disjoint_product (gset (Event τ σ)) (gset (Event τ σ))))
