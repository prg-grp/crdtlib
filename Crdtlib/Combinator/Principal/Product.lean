import Crdtlib.CRDT.Basic

section Product

open Pkg Prod

instance product_zero_σ (σ₁ σ₂ : Type*) [Zero σ₁] [Zero σ₂] : Zero (σ₁ × σ₂) where
  zero := ⟨0, 0⟩

def productₜ [PartialOrder τ] (c₁ : CRDTₜ τ ω σ₁ γ₁) (c₂ : CRDTₜ τ ω σ₂ γ₂)
  : CRDTₜ τ ω (σ₁ × σ₂) (γ₁ × γ₂)
  := {
    effect e s := ⟨c₁.effect e s.1, c₂.effect e s.2⟩,
    interpret s := ⟨c₁.interpret s.1, c₂.interpret s.2⟩,
    commutative e₁ e₂ con := by {
      funext s
      simp only [Function.comp_apply, Prod.mk.injEq]
      constructor
      . exact congrFun (c₁.commutative e₁ e₂ con) (s.1)
      . exact congrFun (c₂.commutative e₁ e₂ con) (s.2)
    },
  }

def product {ω σ₁ γ₁ σ₂ γ₂ : Type*} (c₁ : CRDT ω σ₁ γ₁) (c₂ : CRDT ω σ₂ γ₂)
  : CRDT ω (σ₁ × σ₂) (γ₁ × γ₂)
  := {
    effect e s := ⟨c₁.effect e s.1, c₂.effect e s.2⟩,
    interpret s := ⟨c₁.interpret s.1, c₂.interpret s.2⟩,
    commutative e₁ e₂ := by {
      funext s
      simp only [Function.comp_apply, Prod.mk.injEq]
      constructor
      . exact congrFun (c₁.commutative e₁ e₂) (s.1)
      . exact congrFun (c₂.commutative e₁ e₂) (s.2)
    },
  }

def product3 {ω σ₁ γ₁ σ₂ γ₂ σ₃ γ₃ : Type*} (c₁ : CRDT ω σ₁ γ₁) (c₂ : CRDT ω σ₂ γ₂) (c₃ : CRDT ω σ₃ γ₃)
  : CRDT ω ((σ₁ × σ₂) × σ₃) ((γ₁ × γ₂) × γ₃)
  := product (product c₁ c₂) c₃
