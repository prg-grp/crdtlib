use std::marker::PhantomData;

use crdtlib_api::{Crdt, CrdtT, Datatype, Timed};

/// `const`: ignores every operation and interprets the state as itself.
pub struct Const<O, S>(PhantomData<fn(&O, S) -> S>);

/// `const`
pub fn constant<O, S>() -> Const<O, S> {
  Const(PhantomData)
}

/// `constₜ`
pub fn constant_t<O, S>() -> Timed<Const<O, S>> {
  Timed(constant())
}

impl<O, S: Clone> Datatype for Const<O, S> {
  type Op = O;
  type State = S;
  type Interp = S;

  fn interpret(&self, state: &S) -> S {
    state.clone()
  }
}

impl<O, S: Clone> Crdt for Const<O, S> {
  fn effect(&self, _op: &O, state: S) -> S {
    state
  }
}

/// `const_zero`: ignores every operation and interprets every state as `0`.
pub struct ConstZero<O, S, G>(PhantomData<fn(&O, S) -> (S, G)>);

/// `const_zero`
pub fn const_zero<O, S, G: Default>() -> ConstZero<O, S, G> {
  ConstZero(PhantomData)
}

impl<O, S, G: Default> Datatype for ConstZero<O, S, G> {
  type Op = O;
  type State = S;
  type Interp = G;

  fn interpret(&self, _state: &S) -> G {
    G::default()
  }
}

impl<T: PartialOrd, O, S, G: Default> CrdtT<T> for ConstZero<O, S, G> {
  fn effect_t(&self, _t: &T, _op: &O, state: S) -> S {
    state
  }
}
