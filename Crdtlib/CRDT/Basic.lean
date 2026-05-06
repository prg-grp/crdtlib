import Crdtlib.CRDT.Pkg
import Crdtlib.CRDT.Concurrent

structure CRDT (τ : Type) [PartialOrder τ] (ω σ γ : Type*) where
  effect : Pkg τ ω → σ → σ
  interpret : σ → γ
  commutative : ∀ (e₁ e₂ : Pkg τ ω),
    Concurrent e₁.t e₂.t → (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂)

-- CRDT without timestamps
structure CRDT' (ω σ γ : Type*) where
  effect : ω → σ → σ
  interpret : σ → γ
  commutative : ∀ (e₁ e₂ : ω),
    (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂)

def CRDT.of (τ : Type) [PartialOrder τ] (c : CRDT τ ω σ γ) : CRDT τ ω σ γ := c

def CRDT'.toCRDT (τ : Type) [PartialOrder τ] (c : CRDT' ω σ γ)
  : CRDT τ ω σ γ
  := {
    effect e := c.effect e.v
    interpret := c.interpret
    commutative e₁ e₂ _ := c.commutative e₁.v e₂.v
  }
