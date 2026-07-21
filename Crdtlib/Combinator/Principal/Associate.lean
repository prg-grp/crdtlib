import Crdtlib.CRDT.Basic
import Std.Data.ExtHashMap
import Mathlib.Algebra.Group.Defs
import Mathlib.Order.Defs.LinearOrder

section Associate

open Prod Pkg

instance [DecidableEq κ] [Hashable κ] : Zero $ Std.ExtHashMap κ σ where
  zero := Std.ExtHashMap.emptyWithCapacity 8

abbrev Associate (κ σ : Type*) [DecidableEq κ] [Hashable κ]
  := Std.ExtHashMap κ σ

def Std.ExtHashMap.toListSorted
    [BEq α] [Hashable α] [LE α] [DecidableLE α] [Std.IsLinearOrder α]
    [EquivBEq α] [LawfulHashable α] (x : Std.ExtHashMap α β) : List (α × β) :=
  x.inner.lift (λ x => (Std.DHashMap.Const.toList x).mergeSort λ a b => a.1 ≤ b.1) ?_
where finally
  intro a b h
  open DHashMap.Const in
  have perm : ((toList a).mergeSort (·.1 ≤ ·.1)).Perm ((toList b).mergeSort (·.1 ≤ ·.1)) :=
    (List.mergeSort_perm ..).trans (h.constToList_perm.trans (List.mergeSort_perm ..).symm)
  have pairwise (a : Std.DHashMap α λ _ => β) :
      ((toList a).mergeSort (·.1 ≤ ·.1)).Pairwise (λ a b => decide (a.1 ≤ b.1) = true ∧ (a.1 == b.1) = false) :=
    (List.pairwise_mergeSort (by grind) (by grind) _).and
      (distinct_keys_toList.perm (List.mergeSort_perm ..).symm (by simp [BEq.comm]))
  refine perm.eq_of_pairwise ?_ (pairwise a) (pairwise b)
  intro _ _ _ _ h h'
  simp only [decide_eq_true_eq] at h h'
  have := le_antisymm h.1 h'.1
  simp_all

instance [DecidableEq κ] [Hashable κ] [DecidableEq σ] : DecidableEq (Associate κ σ) := inferInstance

structure AssociateInterp (κ γ : Type*) where
  map : κ → γ
  /-- Enumerate elements in the canonical order induced by `LinearOrder σ`. -/
  toList [LinearOrder κ] : List (κ × γ)

def associateₜ [PartialOrder τ] (κ : Type*) [DecidableEq κ] [Hashable κ] [DecidableEq σ] [Zero σ] (c : CRDTₜ τ ω σ γ)
  : CRDTₜ τ (κ × ω) (Associate κ σ) (AssociateInterp κ γ) := {
    effect e s :=
      s.alter e.v.fst (λ x ↦
        .guard (· ≠ 0) (c.effect (map snd e) (x.getD 0))
      )
    interpret s := {
      map k := c.interpret (s.getD k 0)
      toList := s.map (λ _ ↦ c.interpret) |> Std.ExtHashMap.toListSorted
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
  : CRDT (κ × ω) (Associate κ σ) (AssociateInterp κ γ) := {
    effect e s :=
      s.alter e.fst (λ x ↦
        .guard (· ≠ 0) (c.effect e.snd (x.getD 0))
      )
    interpret s := {
      map k := c.interpret (s.getD k 0)
      toList := s.map (λ _ ↦ c.interpret) |> Std.ExtHashMap.toListSorted
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
