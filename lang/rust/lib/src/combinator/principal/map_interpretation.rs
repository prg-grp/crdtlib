use crdtlib_api::{Crdt, CrdtT, Datatype};

/// `map_interpretation f c`: interprets `c`'s interpretation once more through `f`.
#[derive(Clone, Copy, Debug)]
pub struct MapInterpretation<C, F> {
  f: F,
  c: C,
}

/// `map_interpretation f c` (and `map_interpretationₜ`)
pub fn map_interpretation<C: Datatype, G, F: Fn(C::Interp) -> G>(
  f: F,
  c: C,
) -> MapInterpretation<C, F> {
  MapInterpretation { f, c }
}

impl<C: Datatype, G, F: Fn(C::Interp) -> G> Datatype for MapInterpretation<C, F> {
  type Op = C::Op;
  type State = C::State;
  type Interp = G;

  fn interpret(&self, state: &C::State) -> G {
    (self.f)(self.c.interpret(state))
  }
}

impl<C: Crdt, G, F: Fn(C::Interp) -> G> Crdt for MapInterpretation<C, F> {
  fn effect(&self, op: &C::Op, state: C::State) -> C::State {
    self.c.effect(op, state)
  }
}

impl<T: PartialOrd, C: CrdtT<T>, G, F: Fn(C::Interp) -> G> CrdtT<T> for MapInterpretation<C, F> {
  fn effect_t(&self, t: &T, op: &C::Op, state: C::State) -> C::State {
    self.c.effect_t(t, op, state)
  }
}
