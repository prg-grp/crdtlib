module

public import Crdtlib.Combinator.Principal.MapInterpretation
public import Crdtlib.Combinator.Derived.MapOp
public import Crdtlib.Combinator.Derived.DisjointProduct
public import Crdtlib.CRDT.Std.Set.GSet
public import Mathlib.Data.Finset.Basic

@[expose] public section

-- ANCHOR: orset
inductive OROp (σ tok : Type) where
  | add (elem : σ) (token : tok)
  | remove (observed : Finset (σ × tok))

def orset (σ tok : Type) [DecidableEq σ] [DecidableEq tok] :
    CRDT (OROp σ tok) (Finset (σ × tok) × Finset (σ × tok)) (Finset σ) :=
  map_interpretation (λ ⟨addSet, tombstone⟩ ↦ (addSet \ tombstone).image Prod.fst)
    (map_op (λ | .add elem token => .inl {(elem, token)} | .remove observed => .inr observed)
      (disjoint_product (union_set (σ × tok)) (union_set (σ × tok))))
-- ANCHOR_END: orset
