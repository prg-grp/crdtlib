import Crdtlib.CRDT.Std.Graph.Basic
import Crdtlib.CRDT.Std.Set.TPSet
import Crdtlib.Combinator.Principal.Product
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Principal.Traverse

section MonotonicDag

variable (σ : Type*) [Hashable σ] [DecidableEq σ]

-- structure TPGraphState where
--   verticiesAdded : GHashSetState σ
--   edgesAdded : GHashSetState (σ × σ)
--   verticiesRemoved : GHashSetState σ
--   edgesRemoved : GHashSetState (σ × σ)

def MonotonicDagState := (GHashSetState σ) × (GHashSetState (σ × σ))

inductive MonotonicDagOp where
  | addEdge (edge : σ × σ)
  | addBetween (prev : σ) (elem : σ) (next : σ)

def monotonic_dag [Zero σ] : CRDT (MonotonicDagOp σ) (MonotonicDagState σ) (DagInterpretation σ)
  := id
    $ traverse (λ o : MonotonicDagOp σ ↦ match o with
        | .addEdge edge => [.inr edge]
        | .addBetween prev elem next => [.inl elem, .inr ⟨prev, elem⟩, .inr ⟨elem, next⟩]
      )
    $ map_interpretation (λ ⟨vertices, edges⟩ ↦
      ⟨⟨vertices.mem, λ e@⟨e₁, e₂⟩ ↦ vertices.mem e₁ ∧ vertices.mem e₂ ∧ edges.mem e⟩, sorry⟩)
    $ disjoint_product (ghashset σ) (ghashset (σ × σ))
