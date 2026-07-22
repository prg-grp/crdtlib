import Crdtlib.CRDT.Std.LWW.MVLWW
import Crdtlib.Combinator.Principal.MapInterpretation
import Crdtlib.Combinator.Principal.MapState
import Crdtlib.Combinator.Principal.Traverse
import Crdtlib.Combinator.Derived.DisjointProduct

section TaggedSum

inductive Choice | left | right deriving Hashable, DecidableEq

def Choice.toFin : Choice → Fin 2
  | .left => 0
  | .right => 1

instance : LinearOrder Choice :=
  LinearOrder.lift' Choice.toFin (λ a b h ↦ by cases a <;> cases b <;> simp_all [Choice.toFin])

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

def tagged_union_3 [PartialOrder τ] [DecidableLT τ] [DecidableEq τ]
  (c₁ : CRDTₜ τ ω₁ σ₁ γ₁) (c₂ : CRDTₜ τ ω₂ σ₂ γ₂) (c₃ : CRDTₜ τ ω₃ σ₃ γ₃)
  : CRDTₜ τ ((((ω₁ ⊕ ω₂) ⊕ Choice) ⊕ ω₃) ⊕ Choice)
           ((σ₁ × σ₂ × σ₃) × Finset (Event τ Choice) × Finset (Event τ Choice))
           (((γ₁ ⊕ γ₂) ⊕ γ₃))
  := map_stateₜ
      -- f : source → target
      (λ ⟨⟨⟨⟨s1, s2⟩, inner⟩, s3⟩, outer⟩ ↦ (⟨s1, s2, s3⟩, inner, outer))
      -- f' : target → source
      (λ ⟨⟨s1, s2, s3⟩, inner, outer⟩ ↦ (⟨⟨⟨s1, s2⟩, inner⟩, s3⟩, outer))
      (by rfl)
      (tagged_unionₜ (tagged_unionₜ c₁ c₂) c₃)
