import Crdtlib.CRDT.Basic
import Mathlib.Logic.Function.Defs

section MapInterpretation

open Pkg

def map_interpretationₜ [PartialOrder τ] (f : γ₁ → γ₂) (c : CRDTₜ τ ω σ γ₁) : CRDTₜ τ ω σ γ₂ where
  effect := c.effect
  interpret := f ∘ c.interpret
  commutative e₁ e₂ con := by
    ext s
    simp
    exact congrFun (c.commutative e₁ e₂ con) s

-- ANCHOR: map_interpretation
def map_interpretation (f : γ₁ → γ₂) (c : CRDT ω σ γ₁) : CRDT ω σ γ₂ where
  effect := c.effect
  interpret := f ∘ c.interpret
  commutative e₁ e₂ := by
    ext s
    simp
    exact congrFun (c.commutative e₁ e₂) s
-- ANCHOR_END: map_interpretation
