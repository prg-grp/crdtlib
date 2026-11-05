use std::marker::PhantomData;
use std::vec;

use crdtlib_api::{Crdt, CrdtT, Datatype};

/// `traverse f c`: an operation `o` applies every operation of `f o` to `c`.
pub struct Traverse<C, O, F> {
  f: F,
  c: C,
  _o: PhantomData<fn(&O)>,
}

/// `traverse f c` (and `traverseₜ`, where every operation of `f o` gets the timestamp of `o`)
pub fn traverse<O, C: Datatype, F: Fn(&O) -> Vec<C::Op>>(f: F, c: C) -> Traverse<C, O, F> {
  Traverse {
    f,
    c,
    _o: PhantomData,
  }
}

impl<O, C: Datatype, F: Fn(&O) -> Vec<C::Op>> Datatype for Traverse<C, O, F> {
  type Op = O;
  type State = C::State;
  type Interp = C::Interp;

  fn interpret(&self, state: &C::State) -> C::Interp {
    self.c.interpret(state)
  }
}

impl<O, C: Crdt, F: Fn(&O) -> Vec<C::Op>> Crdt for Traverse<C, O, F> {
  /// `(f o).foldr c.effect`: the last operation of `f o` is applied first.
  fn effect(&self, op: &O, state: C::State) -> C::State {
    (self.f)(op)
      .iter()
      .rev()
      .fold(state, |s, o| self.c.effect(o, s))
  }
}

impl<T: PartialOrd, O, C: CrdtT<T>, F: Fn(&O) -> Vec<C::Op>> CrdtT<T> for Traverse<C, O, F> {
  fn effect_t(&self, t: &T, op: &O, state: C::State) -> C::State {
    (self.f)(op)
      .iter()
      .rev()
      .fold(state, |s, o| self.c.effect_t(t, o, s))
  }
}

/// `traverse_rec lift f c`: `lift` turns an operation into a seed, and `step` unfolds the seed
/// into operations of `c` one at a time, applying them in order. Lean requires `step` to shrink
/// the seed; here `step` must eventually return `None`.
pub struct TraverseRec<C, O, R, L, S> {
  lift: L,
  step: S,
  c: C,
  _o: PhantomData<fn(&O) -> R>,
}

/// `traverse_rec lift f c`
pub fn traverse_rec<O, R, C, L, S>(lift: L, step: S, c: C) -> TraverseRec<C, O, R, L, S>
where
  C: Datatype,
  L: Fn(&O) -> R,
  S: Fn(R) -> Option<(C::Op, R)>,
{
  TraverseRec {
    lift,
    step,
    c,
    _o: PhantomData,
  }
}

impl<O, R, C, L, S> Datatype for TraverseRec<C, O, R, L, S>
where
  C: Datatype,
  L: Fn(&O) -> R,
  S: Fn(R) -> Option<(C::Op, R)>,
{
  type Op = O;
  type State = C::State;
  type Interp = C::Interp;

  fn interpret(&self, state: &C::State) -> C::Interp {
    self.c.interpret(state)
  }
}

impl<O, R, C, L, S> Crdt for TraverseRec<C, O, R, L, S>
where
  C: Crdt,
  L: Fn(&O) -> R,
  S: Fn(R) -> Option<(C::Op, R)>,
{
  /// `recurse_k`
  fn effect(&self, op: &O, mut state: C::State) -> C::State {
    let mut seed = (self.lift)(op);
    while let Some((o, rest)) = (self.step)(seed) {
      state = self.c.effect(&o, state);
      seed = rest;
    }
    state
  }
}

impl<T, O, R, C, L, S> CrdtT<T> for TraverseRec<C, O, R, L, S>
where
  T: PartialOrd,
  C: CrdtT<T>,
  L: Fn(&O) -> R,
  S: Fn(R) -> Option<(C::Op, R)>,
{
  fn effect_t(&self, t: &T, op: &O, mut state: C::State) -> C::State {
    let mut seed = (self.lift)(op);
    while let Some((o, rest)) = (self.step)(seed) {
      state = self.c.effect_t(t, &o, state);
      seed = rest;
    }
    state
  }
}

/// `listStep`
pub fn list_step<A>(mut xs: vec::IntoIter<A>) -> Option<(A, vec::IntoIter<A>)> {
  xs.next().map(|x| (x, xs))
}

/// `traverse_list f c`: `traverse_rec` over the list `f o`, applied front to back.
pub fn traverse_list<O, C: Datatype, F: Fn(&O) -> Vec<C::Op>>(
  f: F,
  c: C,
) -> TraverseRec<
  C,
  O,
  vec::IntoIter<C::Op>,
  impl Fn(&O) -> vec::IntoIter<C::Op>,
  fn(vec::IntoIter<C::Op>) -> Option<(C::Op, vec::IntoIter<C::Op>)>,
> {
  traverse_rec(move |o: &O| f(o).into_iter(), list_step, c)
}

/// `traverse_mapop f c`
pub fn traverse_mapop<O, C: Datatype, F: Fn(&O) -> C::Op>(
  f: F,
  c: C,
) -> TraverseRec<
  C,
  O,
  vec::IntoIter<C::Op>,
  impl Fn(&O) -> vec::IntoIter<C::Op>,
  fn(vec::IntoIter<C::Op>) -> Option<(C::Op, vec::IntoIter<C::Op>)>,
> {
  traverse_list(move |o: &O| vec![f(o)], c)
}
