structure Pkg (τ : Type) (υ : Type u) where
  t : τ
  v : υ

namespace Pkg

instance [Hashable α] : Hashable $ Pkg τ α where
  hash x := Hashable.hash x.2

instance zero_pkg (τ : Type) (υ : Type u) [Zero τ] [Zero υ] : Zero (Pkg τ υ) where
  zero := ⟨0, 0⟩

instance decidable_eq_pkg (τ : Type) (υ : Type u) [DecidableEq τ] [DecidableEq υ] : DecidableEq (Pkg τ υ) := by {
  intro ⟨mx, ex⟩ ⟨my, ey⟩
  by_cases h : mx = my
  . subst h
    by_cases h' : ex = ey
    . subst h'
      exact isTrue rfl
    . exact isFalse (λ con => h' (by cases con; rfl))
  . exact isFalse (λ con => h (by cases con; rfl))
}

@[reducible]
def map (f : υₛ → υₜ) (orig : Pkg τ υₛ) : Pkg τ υₜ := ⟨orig.t, f orig.v⟩

end Pkg
