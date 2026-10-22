module

public import Crdtlib.Combinator.Principal.Product
public import Crdtlib.Combinator.Derived.MapOp

@[expose] public section

-- ANCHOR: joint_product
def joint_product (c₁ : CRDT ω₁ σ₁ γ₁) (c₂ : CRDT ω₂ σ₂ γ₂) :
    CRDT (ω₁ × ω₂) (σ₁ × σ₂) (γ₁ × γ₂) :=
  product (map_op (·.1) c₁) (map_op (·.2) c₂)
-- ANCHOR_END: joint_product
