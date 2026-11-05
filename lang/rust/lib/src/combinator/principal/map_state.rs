use crdtlib_api::{Crdt, CrdtT, Datatype};

/// `map_state f f' c`: stores `c`'s state as `f` of it.
#[derive(Clone, Copy, Debug)]
pub struct MapState<C, F, G> {
  f: F,
  f_inv: G,
  c: C,
}

/// `map_state f f' c` (and `map_stateₜ`). `f'` must be a left inverse of `f` (`f' ∘ f = id`).
pub fn map_state<C: Datatype, S, F: Fn(C::State) -> S, G: Fn(S) -> C::State>(
  f: F,
  f_inv: G,
  c: C,
) -> MapState<C, F, G> {
  MapState { f, f_inv, c }
}

impl<C, S, F, G> Datatype for MapState<C, F, G>
where
  C: Datatype,
  S: Clone,
  F: Fn(C::State) -> S,
  G: Fn(S) -> C::State,
{
  type Op = C::Op;
  type State = S;
  type Interp = C::Interp;

  fn interpret(&self, state: &S) -> C::Interp {
    self.c.interpret(&(self.f_inv)(state.clone()))
  }
}

impl<C, S, F, G> Crdt for MapState<C, F, G>
where
  C: Crdt,
  S: Clone,
  F: Fn(C::State) -> S,
  G: Fn(S) -> C::State,
{
  fn effect(&self, op: &C::Op, state: S) -> S {
    (self.f)(self.c.effect(op, (self.f_inv)(state)))
  }
}

impl<T, C, S, F, G> CrdtT<T> for MapState<C, F, G>
where
  T: PartialOrd,
  C: CrdtT<T>,
  S: Clone,
  F: Fn(C::State) -> S,
  G: Fn(S) -> C::State,
{
  fn effect_t(&self, t: &T, op: &C::Op, state: S) -> S {
    (self.f)(self.c.effect_t(t, op, (self.f_inv)(state)))
  }
}
