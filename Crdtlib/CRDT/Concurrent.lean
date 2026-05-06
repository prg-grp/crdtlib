import Mathlib.Order.Defs.PartialOrder

structure Concurrent {τ : Type} [LE τ] (t₁ t₂ : τ) : Prop where
  concurrent : ¬ (t₁ ≤ t₂) ∧ ¬ (t₂ ≤ t₁)

namespace Concurrent

theorem symm [LE τ] (t₁ t₂ : τ) (c : Concurrent t₁ t₂) : Concurrent t₂ t₁ :=
  let ⟨⟨le₁, le₂⟩⟩ := c
  ⟨le₂, le₁⟩

theorem neq [Preorder τ] {t₁ t₂ : τ} (c : Concurrent t₁ t₂) : t₁ ≠ t₂ := by {
  intro eq
  subst eq
  have ⟨con⟩ := c
  have not_refl := con.left
  have refl := le_refl t₁
  exact not_refl refl
}

end Concurrent
