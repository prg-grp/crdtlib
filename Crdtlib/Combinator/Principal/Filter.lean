import Crdtlib.CRDT.Basic

section Filter

open Pkg Prod

def filterₜ [PartialOrder τ] (p : ω → Bool) (c : CRDTₜ τ { o : ω // p o } σ γ)
  : CRDTₜ τ ω σ γ
  := {
    effect e s := if h : p e.v
      then c.effect { t := e.t, v := ⟨e.v, h⟩ } s
      else s
    interpret := c.interpret
    commutative e₁ e₂ con := by {
      ext s
      by_cases ft₁ : p e₁.v <;> by_cases ft₂ : p e₂.v <;> simp [ft₁, ft₂]
      . exact congrFun (c.commutative { t := e₁.t, v := ⟨e₁.v, ft₁⟩ } { t := e₂.t, v := ⟨e₂.v, ft₂⟩ } con) s
    }
  }

private def filtered (f : ω → Bool) (es : List ω) : List (Σ' e : ω, f e) :=
  es.filterMap (fun o =>
    if h : f o then some ⟨o, h⟩ else none)

def filter (p : ω → Bool) (c : CRDT { o : ω // p o } σ γ)
  : CRDT ω σ γ
  := {
    effect e s := if h : p e
      then c.effect ⟨e, h⟩ s
      else s
    interpret := c.interpret
    commutative e₁ e₂ := by {
      ext s
      by_cases ft₁ : p e₁ <;> by_cases ft₂ : p e₂ <;> simp [ft₁, ft₂]
      . exact congrFun (c.commutative ⟨e₁, ft₁⟩ ⟨e₂, ft₂⟩) s
    }
  }
