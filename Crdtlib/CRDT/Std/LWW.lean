import Crdtlib.CRDT.Primitive.MVReg
import Crdtlib.Combinator.Principal.MapInterpretation
import Mathlib.Data.Finset.Max

section LWW

def lwwₜ (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [LinearOrder σ] [Zero σ]
  : CRDTₜ τ σ (Finset $ Pkg τ σ) σ
  := map_interpretationₜ
    (λ s ↦
      match (s.image (·.v)).max with
        | .none => Zero.zero
        | .some x => x
    )
    (mv_regₜ σ)
