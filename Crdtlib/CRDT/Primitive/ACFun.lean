import Crdtlib.CRDT.Basic
import Mathlib.Algebra.Group.Defs
import Mathlib.Data.Set.Finite.Basic

section ACFun

def ac_fun (α : Type u) (f : α → α → α) [c : Std.Commutative f] [a : Std.Associative f]
  : CRDT α α α
  := {
    effect := f
    interpret := id
    commutative e₁ e₂ := by {
      ext s
      simp
      rw [←a.assoc e₁ e₂, c.comm e₁ e₂, ←a.assoc e₂ e₁]
    }
  }

def counter : CRDT Int Int Int
  := ac_fun Int (· + ·)

def gcounter : CRDT Nat Nat Nat
  := ac_fun Nat (· + ·)

def join (σ : Type) [SemilatticeSup σ] : CRDT σ σ σ := ac_fun σ max

-- examples of join

def union_set (σ : Type) [DecidableEq σ] := join (Finset σ)

def max_int := join Int

variable {τ : Type} [PartialOrder τ]

def ac_funₜ (α : Type) (f : α → α → α) [c : Std.Commutative f] [a : Std.Associative f]
  : CRDTₜ τ α α α
  := (ac_fun α f).toCRDTₜ τ

def counterₜ := counter.toCRDTₜ τ
def gcounterₜ := gcounter.toCRDTₜ τ
def joinₜ (σ : Type) [LinearOrder σ] := join σ |>.toCRDTₜ τ
def union_setₜ (σ : Type) [DecidableEq σ] := union_set σ |>.toCRDTₜ τ
