import Crdtlib.Combinator.Principal.Product
import Crdtlib.Combinator.Principal.Traverse

open Prod
open Pkg

def disjoint_product [PartialOrder τ] (c₁ : CRDT τ ω₁ σ₁ γ₁) (c₂ : CRDT τ ω₂ σ₂ γ₂)
  : CRDT τ (ω₁ ⊕ ω₂) (σ₁ × σ₂) (γ₁ × γ₂)
  := product (traverse (Option.toList ∘ Sum.getLeft?) c₁) (traverse (Option.toList ∘ Sum.getRight?) c₂)

def disjoint_product'.{u1,u2,v1,v2,w1,w2} (c₁ : CRDT'.{u1,v1,w1} ω₁ σ₁ γ₁) (c₂ : CRDT'.{u2,v2,w2} ω₂ σ₂ γ₂)
  : CRDT'.{max u1 u2, max v1 v2, max w1 w2} (ω₁ ⊕ ω₂) (σ₁ × σ₂) (γ₁ × γ₂)
  := product' (traverse' (Option.toList ∘ Sum.getLeft?) c₁) (traverse' (Option.toList ∘ Sum.getRight?) c₂)
