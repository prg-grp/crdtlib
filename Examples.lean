module

public import Crdtlib.CRDT.Std.Set.GSet
public import Crdtlib.CRDT.Std.LWW.MVLWW
public import Crdtlib.Combinator.Principal.Product
public import Crdtlib.Combinator.Principal.Associate
public import Mathlib.Data.String.Basic

@[expose] public section

private instance : Zero String := ⟨""⟩

#check productₜ (gsetₜ String) (mv_lwwₜ String)
