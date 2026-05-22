import Crdtlib.CRDT.Basic
import Std.Data.ExtHashMap
import Mathlib.Algebra.Group.Defs
import Mathlib.Order.Defs.LinearOrder

section Associate

open Prod Pkg

instance [DecidableEq κ] [Hashable κ] [LawfulBEq κ] : Zero $ Std.ExtHashMap κ σ where
  zero := Std.ExtHashMap.emptyWithCapacity 8

abbrev AssociateState (κ σ : Type*) [DecidableEq κ] [Hashable κ] [LawfulBEq κ] [LawfulHashable κ] [Zero σ]
  := Std.ExtHashMap κ σ

structure AssociateInterpretation (κ γ : Type*) where
  map : κ → γ
  /-- Enumerate elements in the canonical order induced by `LinearOrder σ`. -/
  toList [LinearOrder κ] : List (κ × γ)

def associate [PartialOrder τ] (κ : Type*) [DecidableEq κ] [Hashable κ]
    [LawfulBEq κ] [LawfulHashable κ] [Zero σ]
    (c : CRDT τ ω σ γ)
  : CRDT τ (κ × ω) (AssociateState κ σ) (AssociateInterpretation κ γ) := {
    effect e s :=
      s.alter e.v.fst (λ x ↦
        some $ c.effect (map snd e) (x.getD 0)
      )
    interpret s := {
      map k := c.interpret (s.getD k 0)
      toList := sorry -- TODO
    }
    commutative e₁ e₂ con := by {
      funext s
      apply Std.ExtHashMap.ext_getElem?
      intro k
      simp [Std.ExtHashMap.getElem?_alter]
      unfold Pkg.map
      by_cases h₁ : e₁.v.fst = k <;> by_cases h₂ : e₂.v.fst = k
      . rw [if_pos h₁, if_pos h₂]
        subst h₂
        repeat rw [if_pos h₁]
        repeat rw [if_pos h₁.symm]
        simp only [Option.getD_some, Option.some.injEq]
        rw [h₁]
        exact congr_fun (c.commutative (map snd e₁) (map snd e₂) con) _
      . subst h₁
        repeat rw [if_neg h₂]
      . subst h₂
        repeat rw [if_neg h₁]
      . repeat rw [if_neg h₁]
        repeat rw [if_neg h₂]
    }
  }

def associate' (κ : Type*) [DecidableEq κ] [Hashable κ]
    [LawfulBEq κ] [LawfulHashable κ] [Zero σ]
    (c : CRDT' ω σ γ)
  : CRDT' (κ × ω) (AssociateState κ σ) (AssociateInterpretation κ γ) := {
    effect e s :=
      s.alter e.fst (λ x ↦
        some $ c.effect e.2 (x.getD 0)
      )
    interpret s := {
      map k := c.interpret (s.getD k 0)
      toList := sorry -- TODO
    }
    commutative e₁ e₂ := by {
      funext s
      apply Std.ExtHashMap.ext_getElem?
      intro k
      simp [Std.ExtHashMap.getElem?_alter]
      by_cases h₁ : e₁.fst = k <;> by_cases h₂ : e₂.fst = k
      . rw [if_pos h₁, if_pos h₂]
        subst h₂
        repeat rw [if_pos h₁]
        repeat rw [if_pos h₁.symm]
        simp only [Option.getD_some, Option.some.injEq]
        rw [h₁]
        exact congr_fun (c.commutative e₁.snd e₂.snd) _
      . subst h₁
        repeat rw [if_neg h₂]
      . subst h₂
        repeat rw [if_neg h₁]
      . repeat rw [if_neg h₁]
        repeat rw [if_neg h₂]
    }
  }
