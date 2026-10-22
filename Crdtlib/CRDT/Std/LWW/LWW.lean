module

public import Crdtlib.CRDT.Primitive.ACFun
public import Mathlib.Data.Prod.Lex

@[expose] public section

-- ANCHOR: lww
structure Lamport (σ : Type) where (t : Nat) (s : σ)

instance [LinearOrder σ] : LinearOrder (Lamport σ) :=
  LinearOrder.lift'
    (λ x => toLex (x.t, x.s))
    (λ a b h => by obtain ⟨ta, sa⟩ := a; obtain ⟨tb, sb⟩ := b; simpa using h)

def lww (σ : Type) [LinearOrder σ] : CRDT (Lamport σ) (Lamport σ) (Lamport σ) := join (Lamport σ)
-- ANCHOR_END: lww
def lwwₜ [LinearOrder τ] (σ : Type) [LinearOrder σ] := lww σ |>.toCRDTₜ τ
