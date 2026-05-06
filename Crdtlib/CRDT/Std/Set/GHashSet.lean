import Crdtlib.CRDT.Basic
import Crdtlib.CRDT.Std.Set.Basic
import Crdtlib.CRDT.Primitive.ACFun
import Crdtlib.Combinator.Principal.Associate
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.MapOp

section GHashSet

variable (σ : Type*) [Hashable σ] [DecidableEq σ]

def GHashSetState := AssociateState σ ℕ

instance : Zero $ GHashSetState σ where
  zero := Std.ExtHashMap.emptyWithCapacity 8

def ghashset'
  : CRDT' σ (GHashSetState σ) (SetInterpretation σ)
  := map_op' (λ x ↦ ⟨x, 1⟩)
    $ map_interpretation' (λ g ↦ ⟨(· > 0) ∘ g.map, g.foldKeys⟩)
    (associate' σ gcounter')

def ghashset [PartialOrder τ]
  := (ghashset' σ).toCRDT τ
section GHashSetFFI

variable {σ : Type*} [Hashable σ] [DecidableEq σ]

@[export ghashset_empty_u64]
def ghashset_empty_u64 : GHashSetState UInt64 :=
  (0 : GHashSetState UInt64)

@[export ghashset_effect_u64]
def ghashset_effect_u64 (event : UInt64) (state : GHashSetState UInt64)
    : GHashSetState UInt64 :=
  (ghashset' UInt64).effect event state

@[export ghashset_interpret_mem_u64]
def ghashset_interpret_mem_u64 (key : UInt64) (state : GHashSetState UInt64) : Bool :=
  (ghashset' UInt64).interpret state |>.mem key

end GHashSetFFI
