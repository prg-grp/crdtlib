use std::collections::HashMap;
use std::hash::Hash;
use std::marker::PhantomData;

use crdtlib_api::{Crdt, CrdtT, Datatype};

/// `associate κ c`: a copy of `c` for every key, created at `0` (`Default`) on first use.
pub struct Associate<K, C> {
  c: C,
  _k: PhantomData<fn() -> K>,
}

/// `associate κ c` (and `associateₜ`)
pub fn associate<K, C>(c: C) -> Associate<K, C> {
  Associate { c, _k: PhantomData }
}

/// `AssociateInterp κ γ`
#[derive(Clone, Debug, PartialEq)]
pub struct AssociateInterp<K: Eq + Hash, G> {
  entries: HashMap<K, G>,
  default: G,
}

impl<K: Eq + Hash, G> AssociateInterp<K, G> {
  /// `map`: the interpretation at `k`, the interpretation of `0` if `k` was never used.
  pub fn map(&self, k: &K) -> &G {
    self.entries.get(k).unwrap_or(&self.default)
  }

  /// `toList`: the keys in use and their interpretations, ordered by key.
  pub fn to_list(&self) -> Vec<(&K, &G)>
  where
    K: Ord,
  {
    let mut xs: Vec<_> = self.entries.iter().collect();
    xs.sort_by(|a, b| a.0.cmp(b.0));
    xs
  }
}

impl<K: Eq + Hash + Clone, C: Datatype<State: Default>> Datatype for Associate<K, C> {
  type Op = (K, C::Op);
  type State = HashMap<K, C::State>;
  type Interp = AssociateInterp<K, C::Interp>;

  fn interpret(&self, state: &Self::State) -> Self::Interp {
    AssociateInterp {
      entries: state
        .iter()
        .map(|(k, s)| (k.clone(), self.c.interpret(s)))
        .collect(),
      default: self.c.interpret(&C::State::default()),
    }
  }
}

impl<K: Eq + Hash + Clone, C: Crdt<State: Default>> Crdt for Associate<K, C> {
  fn effect(&self, (k, op): &Self::Op, mut state: Self::State) -> Self::State {
    let s = state.remove(k).unwrap_or_default();
    state.insert(k.clone(), self.c.effect(op, s));
    state
  }
}

impl<T: PartialOrd, K: Eq + Hash + Clone, C: CrdtT<T, State: Default>> CrdtT<T>
  for Associate<K, C>
{
  fn effect_t(&self, t: &T, (k, op): &Self::Op, mut state: Self::State) -> Self::State {
    let s = state.remove(k).unwrap_or_default();
    state.insert(k.clone(), self.c.effect_t(t, op, s));
    state
  }
}
