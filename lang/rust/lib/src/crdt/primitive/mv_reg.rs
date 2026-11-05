use std::cmp::Ordering;
use std::collections::HashSet;
use std::hash::Hash;
use std::marker::PhantomData;

use crdtlib_api::{CrdtT, Datatype, Event};

/// `mv_regₜ σ`: a multi-value register holding the writes no later write has seen.
pub struct MvReg<T, O>(PhantomData<fn() -> (T, O)>);

/// `mv_regₜ σ`
pub fn mv_reg_t<T, O>() -> MvReg<T, O> {
  MvReg(PhantomData)
}

impl<T: Clone + Eq + Hash, O: Clone + Eq + Hash> Datatype for MvReg<T, O> {
  type Op = O;
  type State = HashSet<Event<T, O>>;
  type Interp = HashSet<Event<T, O>>;

  fn interpret(&self, state: &Self::State) -> Self::Interp {
    state.clone()
  }
}

impl<T: PartialOrd + Clone + Eq + Hash, O: Clone + Eq + Hash> CrdtT<T> for MvReg<T, O> {
  fn effect_t(&self, t: &T, op: &O, mut state: Self::State) -> Self::State {
    state.retain(|x| x.t.partial_cmp(t) != Some(Ordering::Less));
    state.insert(Event {
      t: t.clone(),
      o: op.clone(),
    });
    state
  }
}
