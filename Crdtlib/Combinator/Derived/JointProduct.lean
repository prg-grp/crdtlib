import Crdtlib.Combinator.Principal.Product
import Crdtlib.Combinator.Derived.MapOp

def joint_product' (c₁ : CRDT' ω₁ σ₁ γ₁) (c₂ : CRDT' ω₂ σ₂ γ₂)
  : CRDT' (ω₁ × ω₂) (σ₁ × σ₂) (γ₁ × γ₂)
  := product' (map_op' (·.1) c₁) (map_op' (·.2) c₂)
