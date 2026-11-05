#![allow(dead_code)]

use std::cmp::Ordering;

use crdtlib::{Crdt, CrdtT};

/// A vector clock, ordered componentwise.
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct VClock(pub Vec<u32>);

impl PartialOrd for VClock {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
    let le = self.0.iter().zip(&other.0).all(|(a, b)| a <= b);
    let ge = self.0.iter().zip(&other.0).all(|(a, b)| a >= b);
    match (le, ge) {
      (true, true) => Some(Ordering::Equal),
      (true, false) => Some(Ordering::Less),
      (false, true) => Some(Ordering::Greater),
      (false, false) => None,
    }
  }
}

pub fn vc(xs: &[u32]) -> VClock {
  VClock(xs.to_vec())
}

pub fn apply<C: Crdt>(c: &C, ops: &[C::Op], s: C::State) -> C::State {
  ops.iter().fold(s, |s, o| c.effect(o, s))
}

pub fn apply_t<T: PartialOrd, C: CrdtT<T>>(c: &C, evs: &[(T, C::Op)], s: C::State) -> C::State {
  evs.iter().fold(s, |s, (t, o)| c.effect_t(t, o, s))
}

/// Check that every pair of operations commutes at `s`.
pub fn assert_commutative<C: Crdt>(c: &C, ops: &[C::Op], s: &C::State)
where
  C::State: Clone + PartialEq,
{
  for a in ops {
    for b in ops {
      assert!(c.commutes(a, b, s));
    }
  }
}

/// Check that every pair of concurrent events commutes at `s`.
pub fn assert_commutative_t<T: PartialOrd, C: CrdtT<T>>(c: &C, evs: &[(T, C::Op)], s: &C::State)
where
  C::State: Clone + PartialEq,
{
  for (t1, a) in evs {
    for (t2, b) in evs {
      assert!(c.commutes_t(t1, a, t2, b, s));
    }
  }
}
