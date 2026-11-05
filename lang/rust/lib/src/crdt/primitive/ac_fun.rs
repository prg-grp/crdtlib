use std::collections::BTreeSet;
use std::marker::PhantomData;

use crdtlib_api::{Crdt, Datatype, SemilatticeSup};

/// `ac_fun α f`: the operation is the argument of `f`, the state its accumulator.
pub struct AcFun<A, F> {
  f: F,
  _a: PhantomData<fn(&A, &A) -> A>,
}

/// `ac_fun α f`. `f` must be associative and commutative (`Std.Associative f`,
/// `Std.Commutative f`).
pub fn ac_fun<A, F: Fn(&A, &A) -> A>(f: F) -> AcFun<A, F> {
  AcFun { f, _a: PhantomData }
}

impl<A: Clone, F: Fn(&A, &A) -> A> Datatype for AcFun<A, F> {
  type Op = A;
  type State = A;
  type Interp = A;

  fn interpret(&self, state: &A) -> A {
    state.clone()
  }
}

impl<A: Clone, F: Fn(&A, &A) -> A> Crdt for AcFun<A, F> {
  fn effect(&self, op: &A, state: A) -> A {
    (self.f)(op, &state)
  }
}

/// `counter`. Lean's `Int` is unbounded; wrapping addition keeps the laws exact.
pub fn counter() -> AcFun<i64, impl Fn(&i64, &i64) -> i64> {
  ac_fun(|a: &i64, b: &i64| a.wrapping_add(*b))
}

/// `gcounter`. Lean's `Nat` is unbounded; wrapping addition keeps the laws exact.
pub fn gcounter() -> AcFun<u64, impl Fn(&u64, &u64) -> u64> {
  ac_fun(|a: &u64, b: &u64| a.wrapping_add(*b))
}

/// `join σ`
pub fn join<A: SemilatticeSup + Clone>() -> AcFun<A, impl Fn(&A, &A) -> A> {
  ac_fun(A::sup)
}

/// `union_set σ`
pub fn union_set<A: Ord + Clone>()
-> AcFun<BTreeSet<A>, impl Fn(&BTreeSet<A>, &BTreeSet<A>) -> BTreeSet<A>> {
  join()
}

/// `max_int`
pub fn max_int() -> AcFun<i64, impl Fn(&i64, &i64) -> i64> {
  join()
}
