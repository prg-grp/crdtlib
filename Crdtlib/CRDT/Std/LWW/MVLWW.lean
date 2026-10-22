module

public import Crdtlib.CRDT.Primitive.MVReg
public import Crdtlib.Combinator.Principal.MapInterpretation
public import Mathlib.Data.Finset.Max

@[expose] public section

section LWW

-- ANCHOR: mv_lww
def mv_lwwₜ (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [LinearOrder σ] [Zero σ] :
    CRDTₜ τ σ (Finset (Event τ σ)) σ :=
  map_interpretationₜ (λ s ↦
      match (s.image (·.o)).max with
        | .none => 0
        | .some x => x
    ) (mv_regₜ σ)
-- ANCHOR_END: mv_lww
