import Crdtlib.CRDT.Basic
import Crdtlib.CRDT.Std.Set.Basic
import Crdtlib.CRDT.Primitive.ACFun
import Crdtlib.Combinator.Principal.Associate
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.MapOp

section GSet

abbrev GSet (σ : Type*) [Hashable σ] [DecidableEq σ] := Associate σ ℕ

instance (σ : Type*) [Hashable σ] [DecidableEq σ] : Zero $ GSet σ where
  zero := Std.ExtHashMap.emptyWithCapacity 8

def gset (σ : Type*) [Hashable σ] [DecidableEq σ] : CRDT σ (GSet σ) (SetInterp σ)
  := map_interpretation
      (λ s ↦ { mem := (· > 0) ∘ s.map, toList := s.toList.filterMap λ ⟨k, v⟩ ↦ if v > 0 then .some k else .none })
      (map_op (λ x ↦ ⟨x, 1⟩)
        (associate σ gcounter))

section GSetFFI

variable {σ : Type*} [Hashable σ] [DecidableEq σ]

@[export gset_empty_u64]
def gset_empty_u64 : GSet UInt64 :=
  (0 : GSet UInt64)

@[export gset_effect_u64]
def gset_effect_u64 (event : UInt64) (state : GSet UInt64)
    : GSet UInt64 :=
  (gset UInt64).effect event state

@[export gset_interpret_mem_u64]
def gset_interpret_mem_u64 (key : UInt64) (state : GSet UInt64) : Bool :=
  (gset UInt64).interpret state |>.mem key

end GSetFFI
