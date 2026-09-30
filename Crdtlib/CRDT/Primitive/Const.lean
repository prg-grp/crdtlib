import Crdtlib.CRDT.Basic

def const : CRDT ω σ σ where
  effect _ := id
  interpret := id
  commutative _ _ := by rfl

def constₜ [PartialOrder τ] : CRDTₜ τ ω σ σ := const.toCRDTₜ τ

def const_zero [PartialOrder τ] [Zero γ] : CRDTₜ τ ω σ γ where
  effect _ := id
  interpret _ := 0
  commutative _ _ _ := by rfl
