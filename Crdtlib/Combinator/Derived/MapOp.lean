module

public import Crdtlib.Combinator.Principal.Traverse

@[expose] public section

def map_opₜ [PartialOrder τ] (f : ωₜ → ωₛ) (c : CRDTₜ τ ωₛ σ γ) : CRDTₜ τ ωₜ σ γ :=
  traverseₜ (List.singleton ∘ f) c

-- ANCHOR: map_op
def map_op (f : ω₂ → ω₁) (c : CRDT ω₁ σ γ) : CRDT ω₂ σ γ :=
  traverse (List.singleton ∘ f) c
-- ANCHOR_END: map_op
