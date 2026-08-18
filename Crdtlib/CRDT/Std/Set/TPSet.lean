import Crdtlib.CRDT.Std.Set.Basic
import Crdtlib.CRDT.Std.Set.GSet
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.DisjointProduct
import Crdtlib.Combinator.Derived.MapOp

section TPSet

def tpset (σ : Type*) [DecidableEq σ] [Hashable σ] [Zero σ] : CRDT (SetOp σ) (GSet σ × GSet σ) (SetInterp σ) :=
  map_interpretation (λ ⟨addSet, removeSet⟩ ↦ {
      mem k := addSet.mem k ∧ ¬ removeSet.mem k, toList := addSet.toList.filter (¬ removeSet.mem ·) })
    (map_op (λ
        | .add    elem => .inl elem
        | .remove elem => .inr elem)
      (disjoint_product (gset σ) (gset σ)))

def tpsetₜ [PartialOrder τ] (σ : Type) [Hashable σ] [Zero σ] [DecidableEq σ] := (tpset σ).toCRDTₜ τ
