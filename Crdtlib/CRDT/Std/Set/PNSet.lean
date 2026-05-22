import Crdtlib.CRDT.Primitive.ACFun
import Crdtlib.CRDT.Std.Set.Basic
import Crdtlib.Combinator.Principal.Associate
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.MapOp

def pnset' (σ : Type*) [DecidableEq σ] [Hashable σ] : CRDT' (SetOp σ) (AssociateState σ Int) (SetInterpretation σ) :=
  map_interpretation'
    (λ elems ↦ {
      mem k := elems.map k > (0 : Int)
      toList := sorry -- TODO
    })
  $ map_op'
    (λ op ↦ match op with
      | .add elem => ⟨elem, 1⟩
      | .remove elem => ⟨elem, -1⟩)
  $ associate' σ (counter')

def pnset [PartialOrder τ] (σ : Type*) [Hashable σ] [Zero σ] [DecidableEq σ] := (pnset' σ).toCRDT τ
