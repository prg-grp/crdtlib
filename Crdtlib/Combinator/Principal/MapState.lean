import Crdtlib.CRDT.Basic
import Mathlib.Logic.Function.Defs

section Iso

open Pkg

def map_stateₜ [PartialOrder τ] (f : σ₁ → σ₂) (f' : σ₂ → σ₁) (iso : f' ∘ f = id) (c : CRDTₜ τ ω σ₁ γ)
  : CRDTₜ τ ω σ₂ γ
  := {
    effect e := f ∘ (c.effect e) ∘ f'
    interpret := c.interpret ∘ f'
    commutative e₁ e₂ con := by {
      ext s
      have h : ∀ x, f' (f x) = x := by {
        intro x
        have := congrFun iso x
        simp at this
        exact this
      }
      have b := congrFun (c.commutative e₁ e₂ con) (f' s)
      simp at b
      unfold Pkg.map at *
      simp [h, b]
    }
  }

def map_state {σ₁ σ₂ ω γ} (f : σ₁ → σ₂) (f' : σ₂ → σ₁) (iso : f' ∘ f = id) (c : CRDT ω σ₁ γ)
  : CRDT ω σ₂ γ
  := {
    effect e := f ∘ (c.effect e) ∘ f'
    interpret := c.interpret ∘ f'
    commutative e₁ e₂ := by {
      ext s
      have h : ∀ x, f' (f x) = x := by {
        intro x
        have := congrFun iso x
        simp at this
        exact this
      }
      have b := congrFun (c.commutative e₁ e₂) (f' s)
      simp at b
      unfold Pkg.map at *
      simp [h, b]
    }
  }
