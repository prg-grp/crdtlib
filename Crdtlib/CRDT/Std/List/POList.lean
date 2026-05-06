import Crdtlib.CRDT.Primitive.ACFun
import Crdtlib.CRDT.Std.Set.GHashSet
import Crdtlib.CRDT.Std.Set.PNSet
import Crdtlib.Combinator.Principal.Associate
import Crdtlib.Combinator.Derived.MapOp
import Crdtlib.Combinator.Derived.JointProduct
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Principal.Traverse
import Crdtlib.Combinator.Derived.DisjointProduct
import Batteries

section POList

open Batteries

instance : Zero (Finset α) where
  zero := ∅

private partial def dfs [DecidableEq σ] [LinearOrder σ] [Hashable σ]
    (verts   : Std.ExtHashMap σ ℕ)
    (outEdges : Std.ExtHashMap σ $ Std.ExtHashMap σ ℕ)
    (active  : σ → ℕ)
    (v       : σ)
    (visited : Finset σ)
    (acc     : List σ)
    : Finset σ × List σ :=
  if v ∈ visited then (visited, acc)
  else
    let visited' := insert v visited
    -- let candidates := (outEdges v).filter (λ _ ↦ verts · > 0) |>.keysArray  .sort (· ≤ ·)
    -- let candidates :=
    --   Std.DHashMap.fold
    --     (fun acc k _ => if verts k > 0 then acc.push k else acc)
    --     #[]
    --     (outEdges v)
    --   |>.toList
    --   |>.mergeSort (· ≤ ·)
    let candidates : List σ := sorry
      -- ((outEdges v).inner.filterMap (fun k _ => if verts k > 0 then some k else none))
      -- |>.toList
      -- |>.mergeSort (· ≤ ·)



    let (visited'', acc') := candidates.foldl
      (λ st x => dfs verts outEdges active x st.1 st.2)
      (visited', acc)
    (visited'', if active v > 0 then v :: acc' else acc')

private def po_traversal {σ : Type*} [DecidableEq σ] [LinearOrder σ] [Bot σ] [Hashable σ]
    (s : (SetInterpretation σ) × (AssociateInterpretation σ (SetInterpretation σ))) : List σ :=
  -- let verts   := s.1.1
  -- let outEdges := s.1.2
  -- let deleted := s.2
  -- let active  := verts \ deleted
  -- let active : σ → ℕ := (λ k ↦ if deleted.getD k 0 > 0 then 0 else verts.getD k 0)
  -- (dfs verts outEdges active ⊥ ∅ []).2
  []

inductive ListOp (σ : Type*) where
  | insert (prev : σ) (elem : σ) (next : σ)
  | remove (elem : σ)

variable (σ : Type*) [Hashable σ] [DecidableEq σ] [Zero σ]

def edges [Hashable σ]
  : CRDT' (σ × σ × σ) (AssociateState σ (GHashSetState σ)) (AssociateInterpretation σ (SetInterpretation σ))
  := traverse'
    (λ ⟨prev, elem, next⟩ ↦ [⟨prev, elem⟩, ⟨elem, next⟩])
    (associate' σ (ghashset' σ))

abbrev POListState [DecidableEq σ] [Hashable σ]
  := (AssociateState σ ℤ) × (AssociateState σ (GHashSetState σ))

def po_list' [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
  : CRDT' (ListOp σ) (POListState σ) (List σ)
  := map_interpretation' po_traversal
    $ traverse'
      (λ op ↦ match op with
        | .insert prev elem next => [.inl $ .add elem, .inr ⟨prev, elem, next⟩]
        | .remove elem => [.inl $ .remove elem]
      )
    $ (disjoint_product'
        -- add-nodes, edges
        (pnset' σ)
        (edges σ))

def po_list {τ : Type} [PartialOrder τ] [LinearOrder σ] [Bot σ] [Zero σ] [Hashable σ]
  : CRDT τ (ListOp σ) (POListState σ) (List σ)
  := (po_list' σ).toCRDT τ

end POList

section POListWithValues

open ListOp

inductive ValueListOp (χ ω : Type*) where
  | mutate (pos : χ) (op : ω)
  | insert (prev : χ) (pos : χ) (next : χ)
  | remove (elem : χ)

variable (χ : Type u) [DecidableEq χ]

def po_list_with_values {τ : Type} [PartialOrder τ] [LinearOrder χ] [Bot χ] [Zero χ] [Hashable χ] [Zero σ] [Zero γ]
  (c : CRDT τ ω σ γ)
  : CRDT τ (ValueListOp χ ω) (AssociateState χ σ × POListState χ) (List (χ × γ))
  := id
    $ map_interpretation (λ ⟨g, l⟩ ↦ l.map (λ x ↦ ⟨x, g.map x⟩))
    $ map_op (λ op ↦ match op with
      | .mutate pos op => .inl ⟨pos, op⟩
      | .insert prev pos next => .inr $ .insert prev pos next
      | .remove pos => .inr $ .remove pos)
    $ disjoint_product (associate χ c) (po_list χ)

end POListWithValues
