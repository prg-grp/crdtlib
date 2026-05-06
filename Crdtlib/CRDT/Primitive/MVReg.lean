import Crdtlib.CRDT.Basic
import Mathlib.Data.Set.Finite.Basic

section MVReg

def mv_reg (σ : Type) [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] [LinearOrder σ]
  : CRDT τ σ (Finset $ Pkg τ σ) (Finset $ Pkg τ σ)
  := {
    effect e s :=
      -- unfortunately this does not improve the complexity because the filter must go through all elements in the worst case
      -- the maximum number of elements in the set is equal to the number of replicas in the network
      -- insert e (Std.HashSet.filter (λ x ↦ ¬ x.t < e.t) s)
      insert e (Finset.filter (λ x ↦ ¬ x.t < e.t) s)
    interpret := id
    commutative e₁ e₂ con := by {
      ext s a
      have neq : e₁ ≠ e₂ := by {
        have neq_t : e₁.t ≠ e₂.t := con.neq
        intro eq
        rw [eq] at neq_t
        exact neq_t rfl
      }
      by_cases heq₁ : a = e₁ <;> by_cases heq₂ : a = e₂ <;> simp [heq₁, heq₂]
      . subst heq₁ heq₂
        contradiction
      . simp [neq]
        intro h
        exact con.concurrent.left $ le_of_lt h
      . simp [neq.symm]
        intro h
        exact con.concurrent.right $ le_of_lt h
      . constructor <;> intro h <;> constructor
        . exact ⟨h.left.left, h.right⟩
        . exact h.left.right
        . exact ⟨h.left.left, h.right⟩
        . exact h.left.right
    }
  }
