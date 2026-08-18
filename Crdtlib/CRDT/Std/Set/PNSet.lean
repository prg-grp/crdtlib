import Crdtlib.CRDT.Primitive.ACFun
import Crdtlib.CRDT.Std.Set.Basic
import Crdtlib.Combinator.Principal.Associate
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.MapOp

def pnset (σ : Type*) [DecidableEq σ] [Hashable σ] : CRDT (SetOp σ) (Associate σ Int) (SetInterp σ) :=
  map_interpretation (λ s ↦ {
      mem := (· > (0 : ℤ)) ∘ s.map,
      toList := s.toList.filterMap λ ⟨k, v⟩ ↦ if v > 0 then .some k else .none })
    (map_op (λ | .add elem => ⟨elem, 1⟩ | .remove elem => ⟨elem, -1⟩)
      (associate σ counter))

def pnsetₜ [PartialOrder τ] (σ : Type*) [Hashable σ] [Zero σ] [DecidableEq σ] := (pnset σ).toCRDTₜ τ
