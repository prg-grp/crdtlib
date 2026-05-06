import Mathlib.Algebra.Group.Defs

section SetBasic

variable (σ : Type*)

inductive SetOp where
  | add (elem : σ)
  | remove (elem : σ)

structure SetInterpretation where
  mem : σ → Bool
  fold {α : Type} (op : α → α → α) [AddCommMonoid α] (a : α) (lift : σ → α) : α
