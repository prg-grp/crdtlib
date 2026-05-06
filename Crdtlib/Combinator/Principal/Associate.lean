import Crdtlib.CRDT.Basic
import Std.Data.ExtHashMap
import Mathlib.Algebra.Group.Defs

section Associate

open Prod Pkg

instance [DecidableEq κ] [Hashable κ] [LawfulBEq κ] : Zero $ Std.ExtHashMap κ σ where
  zero := Std.ExtHashMap.emptyWithCapacity 8

abbrev AssociateState (κ σ : Type*) [DecidableEq κ] [Hashable κ] [LawfulBEq κ] [LawfulHashable κ] [Zero σ]
  := Std.ExtHashMap κ σ

structure AssociateInterpretation (κ γ : Type*) where
  map : κ → γ
  foldKeys {α : Type} (op : α → α → α) [AddCommMonoid α] (a : α) (lift : κ → α) : α
  foldValues {α : Type} (op : α → α → α) [AddCommMonoid α] (a : α) (lift : γ → α) : α

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
      foldKeys op acmon init lift := init -- TODO
      foldValues op acmon init lift := init -- TODO
    }
    commutative e₁ e₂ con := by sorry
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
      foldKeys op acmon init lift := init -- TODO
      foldValues op acmon init lift := init -- TODO
    }
    commutative e₁ e₂ := by sorry
  }
