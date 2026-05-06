import Crdtlib.CRDT.Primitive.MVReg
import Crdtlib.Combinator.Principal.MapInterpretation
import Mathlib.Data.Finset.Max

section LWW

def lww (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [LinearOrder σ] [Zero σ]
  : CRDT τ σ (Finset $ Pkg τ σ) σ
  := map_interpretation
    (λ s ↦
      match (s.image (·.v)).max with
        | .none => Zero.zero
        | .some x => x
    )
    (mv_reg σ)
