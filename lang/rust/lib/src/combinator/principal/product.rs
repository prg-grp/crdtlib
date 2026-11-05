use crdtlib_api::{Crdt, CrdtT, Datatype};

#[derive(Clone, Copy, Debug)]
pub struct Product<A, B>(pub A, pub B);

pub fn product<A, B>(c1: A, c2: B) -> Product<A, B> {
  Product(c1, c2)
}

/// `product3 c₁ c₂ c₃`
pub fn product3<A, B, C>(c1: A, c2: B, c3: C) -> Product<Product<A, B>, C> {
  product(product(c1, c2), c3)
}

impl<A: Datatype, B: Datatype<Op = A::Op>> Datatype for Product<A, B> {
  type Op = A::Op;
  type State = (A::State, B::State);
  type Interp = (A::Interp, B::Interp);

  fn interpret(&self, state: &Self::State) -> Self::Interp {
    (self.0.interpret(&state.0), self.1.interpret(&state.1))
  }
}

impl<A: Crdt, B: Crdt<Op = A::Op>> Crdt for Product<A, B> {
  fn effect(&self, op: &A::Op, state: Self::State) -> Self::State {
    (self.0.effect(op, state.0), self.1.effect(op, state.1))
  }
}

impl<T: PartialOrd, A: CrdtT<T>, B: CrdtT<T, Op = A::Op>> CrdtT<T> for Product<A, B> {
  fn effect_t(&self, t: &T, op: &A::Op, state: Self::State) -> Self::State {
    (
      self.0.effect_t(t, op, state.0),
      self.1.effect_t(t, op, state.1),
    )
  }
}
