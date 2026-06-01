import Crdtlib.CRDT.Std.LWW.MVLWW
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Principal.Traverse
import Crdtlib.Combinator.Derived.DisjointProduct

section TaggedSum

inductive Choice
| left : Choice
| right : Choice
deriving Hashable

instance choiceLinearOrder : LinearOrder Choice where
  le x y := match x, y with
    | Choice.left, Choice.right => True
    | Choice.right, Choice.right => True
    | Choice.right, Choice.left => False
    | Choice.left, Choice.left => True
  lt x y := match x, y with
    | Choice.left, Choice.right => True
    | _, _ => false
  le_refl x := by cases x <;> simp
  le_trans x y z := by cases x <;> cases y <;> cases z <;> simp
  le_antisymm x y := by cases x <;> cases y <;> simp
  le_total x y := by cases x <;> cases y <;> simp
  toDecidableLE x y := by cases x <;> cases y <;> (first | apply instDecidableTrue | apply instDecidableFalse)
  lt_iff_le_not_ge x y := by cases x <;> cases y <;> simp

instance tagged_union_zero_choice : Zero Choice where
  zero := Choice.left

def tagged_unionₜ [PartialOrder τ] [DecidableLT τ] [DecidableEq τ]
  (c₁ : CRDTₜ τ ω₁ σ₁ γ₁) (c₂ : CRDTₜ τ ω₂ σ₂ γ₂)
  : CRDTₜ τ ((ω₁ ⊕ ω₂) ⊕ Choice) ((σ₁ × σ₂) × (Finset (Event τ Choice))) (γ₁ ⊕ γ₂)
  := map_interpretationₜ (λ ⟨⟨l, r⟩, choice⟩ ↦
        match choice with -- map to correct substate depending on the choice
          | .left => Sum.inl l
          | .right => Sum.inr r)
      $ disjoint_productₜ (disjoint_productₜ c₁ c₂) (mv_lwwₜ Choice)

def auto_tagged_unionₜ [PartialOrder τ] [DecidableLT τ] [DecidableEq τ]
  (c₁ : CRDTₜ τ ω₁ σ₁ γ₁) (c₂ : CRDTₜ τ ω₂ σ₂ γ₂)
  : CRDTₜ τ (ω₁ ⊕ ω₂) ((σ₁ × σ₂) × (Finset (Event τ Choice))) (γ₁ ⊕ γ₂)
  := traverseₜ (λ o ↦
      match o with
        | l@(.inl _) => [Sum.inl l, Sum.inr Choice.left]
        | r@(.inr _) => [Sum.inl r, Sum.inr Choice.right]
    ) (tagged_unionₜ c₁ c₂)
