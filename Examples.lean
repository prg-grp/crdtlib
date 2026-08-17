import Crdtlib.CRDT.Std.Set.GSet
import Crdtlib.CRDT.Std.LWW.MVLWW
import Crdtlib.Combinator.Principal.Product
import Crdtlib.Combinator.Principal.Associate
import Mathlib.Data.String.Basic

private instance : Zero String := ⟨""⟩

#check productₜ (gsetₜ String) (mv_lwwₜ String)
