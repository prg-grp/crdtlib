import Crdtlib.CRDT.Basic
import Std.Data.ExtHashMap
import Mathlib.Algebra.Group.Defs
import Mathlib.Order.Defs.LinearOrder

section Associate

open Prod Pkg

instance [DecidableEq κ] [Hashable κ] : Zero $ Std.ExtHashMap κ σ where
  zero := Std.ExtHashMap.emptyWithCapacity 8

abbrev AssociateState (κ σ : Type*) [DecidableEq κ] [Hashable κ]
  := Std.ExtHashMap κ σ

instance [DecidableEq κ] [Hashable κ] [DecidableEq σ] : DecidableEq (AssociateState κ σ) := inferInstance

structure AssociateInterpretation (κ γ : Type*) where
  map : κ → γ
  /-- Enumerate elements in the canonical order induced by `LinearOrder σ`. -/
  toList [LinearOrder κ] : List (κ × γ)

def associateₜ [PartialOrder τ] (κ : Type*) [DecidableEq κ] [Hashable κ] [DecidableEq σ] [Zero σ] (c : CRDTₜ τ ω σ γ)
  : CRDTₜ τ (κ × ω) (AssociateState κ σ) (AssociateInterpretation κ γ) := {
    effect e s :=
      s.alter e.v.fst (λ x ↦
        .guard (· ≠ 0) (c.effect (map snd e) (x.getD 0))
      )
    interpret s := {
      map k := c.interpret (s.getD k 0)
      toList := [] -- TODO (only for interpretation, not used in benchmarks)
    }
    commutative e₁ e₂ con := by {
      funext s
      apply Std.ExtHashMap.ext_getElem?
      intro k
      simp [Std.ExtHashMap.getElem?_alter]
      unfold Pkg.map Option.guard
      by_cases h₁ : e₁.v.fst = k <;> by_cases h₂ : e₂.v.fst = k
      . rw [if_pos h₁, if_pos h₂]
        subst h₂
        iterate 2 rw [if_pos h₁]
        iterate 2 repeat rw [if_pos h₁.symm]
        have helper : ∀ x : σ, (if (!decide (x = 0)) = true then some x else none).getD 0 = x := by {
          intro x
          by_cases h : x = 0 <;> simp [h]
        }
        simp only [helper]
        rw [← h₁]
        have key := congr_fun (c.commutative (map snd e₁) (map snd e₂) con) (s[e₁.v.fst]?.getD 0)
        simp only [Function.comp_apply] at key
        rw [key]
      . subst h₁
        repeat rw [if_neg h₂]
      . subst h₂
        repeat rw [if_neg h₁]
      . repeat rw [if_neg h₁]
        repeat rw [if_neg h₂]
    }
  }

def associate (κ : Type*) [DecidableEq κ] [Hashable κ] [DecidableEq σ] [Zero σ] (c : CRDT ω σ γ)
  : CRDT (κ × ω) (AssociateState κ σ) (AssociateInterpretation κ γ) := {
    effect e s :=
      s.alter e.fst (λ x ↦
        .guard (· ≠ 0) (c.effect e.snd (x.getD 0))
      )
    interpret s := {
      map k := c.interpret (s.getD k 0)
      toList := [] -- TODO (only for interpretation, not used in benchmarks)
    }
    commutative e₁ e₂ := by {
      funext s
      apply Std.ExtHashMap.ext_getElem?
      intro k
      simp [Std.ExtHashMap.getElem?_alter]
      unfold Option.guard
      by_cases h₁ : e₁.fst = k <;> by_cases h₂ : e₂.fst = k
      . rw [if_pos h₁, if_pos h₂]
        subst h₂
        iterate 2 rw [if_pos h₁]
        iterate 2 repeat rw [if_pos h₁.symm]
        have helper : ∀ x : σ, (if (!decide (x = 0)) = true then some x else none).getD 0 = x := by {
          intro x
          by_cases h : x = 0 <;> simp [h]
        }
        simp only [helper]
        rw [← h₁]
        have key := congr_fun (c.commutative e₁.snd e₂.snd) (s[e₁.fst]?.getD 0)
        simp only [Function.comp_apply] at key
        rw [key]
      . subst h₁
        repeat rw [if_neg h₂]
      . subst h₂
        repeat rw [if_neg h₁]
      . repeat rw [if_neg h₁]
        repeat rw [if_neg h₂]
    }
  }
