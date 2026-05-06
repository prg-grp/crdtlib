import Crdtlib.CRDT.Basic
import Mathlib.Algebra.Group.Defs
import Mathlib.Data.Set.Finite.Basic

section ACFun

def ac_fun' (α : Type u) (f : α → α → α) [c : Std.Commutative f] [a : Std.Associative f]
  : CRDT'.{u,u,u} α α α
  := {
    effect := f
    interpret := id
    commutative e₁ e₂ := by {
      ext s
      simp
      rw [←a.assoc e₁ e₂, c.comm e₁ e₂, ←a.assoc e₂ e₁]
    }
  }

def counter' : CRDT' Int Int Int
  := ac_fun' Int (· + ·)

def lww' (σ : Type) [LinearOrder σ] : CRDT' σ σ σ
  := ac_fun' σ max

def gcounter' : CRDT' Nat Nat Nat
  := ac_fun' Nat (· + ·)

variable {τ : Type} [PartialOrder τ]

def ac_fun (α : Type) (f : α → α → α) [c : Std.Commutative f] [a : Std.Associative f]
  : CRDT τ α α α
  := (ac_fun' α f).toCRDT τ

def counter := counter'.toCRDT τ
