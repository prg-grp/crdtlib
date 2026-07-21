import Mathlib.Algebra.Group.Defs
import Mathlib.Data.Multiset.AddSub
import Mathlib.Data.Multiset.Sort

section SetBasic
variable (σ : Type*)

inductive SetOp where
  | add (elem : σ)
  | remove (elem : σ)

structure SetInterp where
  /-- Test set membership -/
  mem : σ → Bool
  /-- Enumerate elements in the canonical order induced by `LinearOrder σ`. -/
  toList [LinearOrder σ] : List σ

-- namespace SetInterp
-- variable [DecidableEq σ] [LinearOrder σ]

-- private instance instAddCommMonoid' {α : Type*} : AddCommMonoid (Multiset α) where
--   add := (· + ·)
--   add_assoc := Multiset.add_assoc
--   zero := 0
--   zero_add := Multiset.zero_add
--   add_zero := Multiset.add_zero
--   add_comm := Multiset.add_comm
--   nsmul := nsmulRec

-- /-- Enumerate elements in the canonical order induced by `LinearOrder σ`. -/
-- def toList (s : SetInterp σ) : List σ :=
--   (s.fold (· + ·) (0 : Multiset σ) ({·})).sort (· ≤ ·)

-- end SetInterp
end SetBasic
