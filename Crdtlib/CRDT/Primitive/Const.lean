import Crdtlib.CRDT.Basic

def const'
  : CRDT' ω σ σ
  := {
    effect _ := id
    interpret := id
    commutative _ _ := by rfl
  }

def const [PartialOrder τ] : CRDT τ ω σ σ := const'.toCRDT τ

def const_zero [PartialOrder τ] [Zero γ]
  : CRDT τ ω σ γ
  := {
    effect _ := id
    interpret _ := 0
    commutative _ _ _ := by rfl
  }
