import Mathlib.Tactic.TypeStar

section GraphBasic

variable (σ : Type*)

inductive GraphOp where
  | addVertex (vertex : σ)
  | removeVertex (vertex : σ)
  | addEdge (edge : σ × σ)
  | removeEdge (edge : σ × σ)

structure GraphInterpretation where
  lookupVertex (vertex : σ) : Bool
  lookupEdge (edge : σ × σ) : Bool

structure DagInterpretation where
  graph : GraphInterpretation σ
  path (edge : σ × σ) : Bool
