import Crdtlib.CRDT.Std.Graph.Basic
import Crdtlib.CRDT.Std.Set.TPSet
import Crdtlib.Combinator.Principal.Product
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Derived.MapOp

section TPGraph

variable (σ : Type*) [Hashable σ] [DecidableEq σ]

-- structure TPGraphState where
--   verticiesAdded : GHashSetState σ
--   edgesAdded : GHashSetState (σ × σ)
--   verticiesRemoved : GHashSetState σ
--   edgesRemoved : GHashSetState (σ × σ)

def TPGraphState := (TPSetState σ) × (TPSetState (σ × σ))

def tpgraph' [Zero σ] : CRDT' (GraphOp σ) (TPGraphState σ) (GraphInterpretation σ)
  := id
    $ map_op' (λ o : GraphOp σ ↦ match o with
        | .addVertex vertex => .inl $ .add vertex
        | .removeVertex vertex => .inl $ .remove vertex
        | .addEdge edge => .inr $ .add edge
        | .removeEdge edge => .inr $ .remove edge
      )
    $ map_interpretation' (λ ⟨vertices, edges⟩ ↦ ⟨vertices.mem, λ e@⟨e₁, e₂⟩ ↦ vertices.mem e₁ ∧ vertices.mem e₂ ∧ edges.mem e⟩)
    $ disjoint_product' (tpset' σ) (tpset' (σ × σ))
