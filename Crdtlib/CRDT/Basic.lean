import Crdtlib.CRDT.Pkg
import Crdtlib.CRDT.Concurrent

structure CRDTₜ (τ : Type) [PartialOrder τ] (ω σ γ : Type*) where
  effect : Event τ ω → σ → σ
  interpret : σ → γ
  commutative : ∀ (e₁ e₂ : Event τ ω),
    Concurrent e₁.t e₂.t → (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂)

-- CRDT without timestamps
structure CRDT (ω σ γ : Type*) where
  effect : ω → σ → σ
  interpret : σ → γ
  commutative : ∀ (e₁ e₂ : ω),
    (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂)

def CRDTₜ.of (τ : Type) [PartialOrder τ] (c : CRDTₜ τ ω σ γ) : CRDTₜ τ ω σ γ := c

def CRDT.toCRDTₜ (τ : Type) [PartialOrder τ] (c : CRDT ω σ γ)
  : CRDTₜ τ ω σ γ
  := {
    effect e := c.effect e.o
    interpret := c.interpret
    commutative e₁ e₂ _ := c.commutative e₁.o e₂.o
  }
