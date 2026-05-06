import Crdtlib.CRDT.Basic
import Mathlib.Tactic.Conv
import Batteries.Logic

section Traverse

private def recurse'_k {F : Type u} [SizeOf F]
    (f : (o : F) → Option (ωₛ × ((o' : F) ×' sizeOf o' < sizeOf o)))
    (effect : ωₛ → σ → σ) (o : F) : σ → σ :=
  match f o with
  | .none => id
  | .some ⟨oₛ, oₜ⟩ => (recurse'_k f effect oₜ.1) ∘ effect oₛ
termination_by sizeOf o
decreasing_by exact oₜ.2

private lemma recurse'_k_comm_single {F : Type u} [SizeOf F]
    (f : (o : F) → Option (ωₛ × ((o' : F) ×' sizeOf o' < sizeOf o)))
    (effect : ωₛ → σ → σ)
    (comm : ∀ e₁ e₂, (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂))
    (o : F) (y : ωₛ) (t : σ) :
    recurse'_k f effect o (effect y t) = effect y (recurse'_k f effect o t) := by {
      conv_lhs => rw [recurse'_k]
      conv_rhs => rw [recurse'_k]
      match h : f o with
        | .none => simp
        | .some ⟨oₛ, oₜ⟩ =>
          simp only [Function.comp]
          have hxy : effect oₛ (effect y t) = effect y (effect oₛ t) := by {
            have := congr_fun (comm oₛ y) t
            simp only [Function.comp] at this
            exact this.symm
          }
          rw [hxy, recurse'_k_comm_single f effect comm oₜ.1 y (effect oₛ t)]
    }
termination_by sizeOf o
decreasing_by exact oₜ.2

private lemma recurse'_k_comm {F : Type u} [SizeOf F]
    (f : (o : F) → Option (ωₛ × ((o' : F) ×' sizeOf o' < sizeOf o)))
    (effect : ωₛ → σ → σ)
    (comm : ∀ e₁ e₂, (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂))
    (o₁ o₂ : F) (t : σ) :
    recurse'_k f effect o₁ (recurse'_k f effect o₂ t) =
    recurse'_k f effect o₂ (recurse'_k f effect o₁ t) := by {
      conv_lhs => rw [recurse'_k]
      match h : f o₁ with
        | .none =>
          have hrhs : recurse'_k f effect o₁ t = t := by rw [recurse'_k, h]; simp
          rw [hrhs]
          rfl
        | .some ⟨oₛ, oₜ⟩ =>
          simp only [Function.comp]
          rw [recurse'_k_comm_single f effect comm o₂ oₛ t |>.symm]
          rw [recurse'_k_comm f effect comm oₜ.1 o₂ (effect oₛ t)]
          have hfold : recurse'_k f effect o₁ t = recurse'_k f effect oₜ.1 (effect oₛ t) := by
            rw [recurse'_k, h]; simp only [Function.comp]
          rw [← hfold]
    }
termination_by sizeOf o₁
decreasing_by exact oₜ.2

def traverse_rec' {F : Type u} [SizeOf F] (lift : ωₜ → F)
    (f : (o : F) → Option (ωₛ × ((o' : F) ×' sizeOf o' < sizeOf o)))
    (c : CRDT' ωₛ σ γ) : CRDT' ωₜ σ γ := {
  effect e := recurse'_k f c.effect (lift e)
  interpret := c.interpret
  commutative e₁ e₂ := by
    ext s
    exact (recurse'_k_comm f c.effect c.commutative (lift e₁) (lift e₂) s).symm
}

private def listStep : (o : List ωₛ) → Option (ωₛ × ((o' : List ωₛ) ×' sizeOf o' < sizeOf o))
  | .nil => .none
  | .cons x xs => .some ⟨x, xs, by simp⟩

def traverse_list' (f : ωₜ → List ωₛ) (c : CRDT' ωₛ σ γ) : CRDT' ωₜ σ γ :=
  traverse_rec' f listStep c

def traverse_mapop' (f : ωₜ → ωₛ) (c : CRDT' ωₛ σ γ)
  : CRDT' ωₜ σ γ
  := traverse_list' (λ x ↦ [f x]) c

private lemma foldr_comm_single' (φ : ω₁ → σ → σ) (comm : ∀ e₁ e₂ : ω₁, (φ e₂) ∘ (φ e₁) = (φ e₁) ∘ (φ e₂)) (xs : List ω₁) (y : ω₁) (t : σ) :
    xs.foldr φ (φ y t) = φ y (xs.foldr φ t) := by
  induction xs generalizing t with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.foldr_cons]
    rw [ih]
    exact (congr_fun (comm x y) _).symm

private lemma foldr_comm' (φ : ω₁ → σ → σ) (comm : ∀ e₁ e₂ : ω₁, (φ e₂) ∘ (φ e₁) = (φ e₁) ∘ (φ e₂)) (xs ys : List ω₁) (t : σ) :
    xs.foldr φ (ys.foldr φ t) = ys.foldr φ (xs.foldr φ t) := by
  induction xs generalizing t with
  | nil => simp
  | cons x xs ih =>
    simp only [List.foldr_cons]
    rw [ih, ← foldr_comm_single' φ comm]

-- same as traverse_list'
def traverse' (f : ω₂ → List ω₁) (c : CRDT' ω₁ σ γ) : CRDT' ω₂ σ γ
  := {
    effect e := (f e).foldr c.effect
    interpret := c.interpret
    commutative e₁ e₂ := by {
      ext _
      exact foldr_comm' c.effect c.commutative _ _ _
    }
  }

private lemma foldr_comm_single_timed
    [PartialOrder τ]
    (c : CRDT τ ω₁ σ γ)
    (t₁ t₂ : τ) (con : Concurrent t₁ t₂)
    (xs : List ω₁) (y : ω₁) (s : σ) :
    xs.foldr (λ o ↦ c.effect ⟨t₁, o⟩)
             (c.effect ⟨t₂, y⟩ s) =
    c.effect ⟨t₂, y⟩
             (xs.foldr (λ o ↦ c.effect ⟨t₁, o⟩) s) := by
  induction xs generalizing s with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.foldr_cons]
    rw [ih]
    exact (congr_fun (c.commutative ⟨t₁, x⟩ ⟨t₂, y⟩ con) _).symm

private lemma foldr_comm_timed
    [PartialOrder τ]
    (c : CRDT τ ω₁ σ γ)
    (t₁ t₂ : τ) (con : Concurrent t₁ t₂)
    (xs ys : List ω₁) (s : σ) :
    xs.foldr (λ o ↦ c.effect ⟨t₁, o⟩)
             (ys.foldr (λ o ↦ c.effect ⟨t₂, o⟩) s) =
    ys.foldr (λ o ↦ c.effect ⟨t₂, o⟩)
             (xs.foldr (λ o ↦ c.effect ⟨t₁, o⟩) s) := by
  induction xs generalizing s with
  | nil => simp
  | cons x xs ih =>
    simp only [List.foldr_cons]
    rw [ih]
    exact (foldr_comm_single_timed c t₂ t₁ con.symm ys x
          (xs.foldr (λ o ↦ c.effect ⟨t₁, o⟩) s)).symm

def traverse [PartialOrder τ] (f : ω₂ → List ω₁) (c : CRDT τ ω₁ σ γ)
  : CRDT τ ω₂ σ γ
  := {
    effect := λ e ↦ (f e.v).foldr (λ o ↦ c.effect ⟨e.t, o⟩)
    interpret := c.interpret
    commutative e₁ e₂ con := by
      ext s
      simp only [Function.comp]
      exact foldr_comm_timed c e₂.t e₁.t (con.symm) (f e₂.v) (f e₁.v) s
  }
