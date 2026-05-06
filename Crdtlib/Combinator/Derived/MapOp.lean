import Crdtlib.Combinator.Principal.Traverse

def map_op [PartialOrder τ] (f : ωₜ → ωₛ) (c : CRDT τ ωₛ σ γ)
  : CRDT τ ωₜ σ γ
  := traverse (List.singleton ∘ f) c

def map_op' (f : ω₂ → ω₁) (c : CRDT' ω₁ σ γ)
  : CRDT' ω₂ σ γ
  := traverse' (List.singleton ∘ f) c
