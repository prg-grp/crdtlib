import Crdtlib.CRDT.Basic
import Mathlib.Logic.Function.Defs

section MapInterpretation

open Pkg

def map_interpretation [PartialOrder τ] (f : γ₁ → γ₂) (c : CRDT τ ω σ γ₁)
  : CRDT τ ω σ γ₂
  := {
    effect := c.effect
    interpret := f ∘ c.interpret
    commutative e₁ e₂ con := by {
      ext s
      simp
      exact congrFun (c.commutative e₁ e₂ con) s
    }
  }

def map_interpretation' (f : γ₁ → γ₂) (c : CRDT' ω σ γ₁)
  : CRDT' ω σ γ₂
  := {
    effect := c.effect
    interpret := f ∘ c.interpret
    commutative e₁ e₂ := by {
      ext s
      simp
      exact congrFun (c.commutative e₁ e₂) s
    }
  }
