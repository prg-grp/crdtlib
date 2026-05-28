import Crdtlib.CRDT.Std.Set.Basic
import Crdtlib.CRDT.Std.Set.GHashSet
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.DisjointProduct
import Crdtlib.Combinator.Derived.MapOp

section TPSet

variable (σ : Type*) [Hashable σ] [DecidableEq σ]

def TPSetState := (GHashSetState σ × GHashSetState σ)

def tpset [DecidableEq σ] [Hashable σ] [Zero σ] : CRDT (SetOp σ) (TPSetState σ) (SetInterpretation σ) :=
  map_interpretation
    (λ ⟨addSet, removeSet⟩ ↦ {
      mem k := addSet.mem k ∧ ¬ removeSet.mem k
      toList := []
    })
    (map_op
      (λ op ↦ match op with
        | .add    elem => .inl elem
        | .remove elem => .inr elem)
      (disjoint_product (ghashset σ) (ghashset σ))
    )

def tpsetₜ [PartialOrder τ] (σ : Type) [Hashable σ] [Zero σ] [DecidableEq σ] := (tpset σ).toCRDTₜ τ
