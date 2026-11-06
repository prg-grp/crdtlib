use std::collections::HashSet;
use std::hash::Hash;

use crate::combinator::derived::disjoint_product::disjoint_product;
use crate::combinator::principal::map_interpretation::map_interpretation;
use crate::combinator::principal::map_state::map_state;
use crate::combinator::principal::traverse::traverse;
use crate::crdt::stdlib::lww::mv_lww_t;
use crdtlib_api::{CrdtT, Event, Sum};

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Choice {
  #[default]
  Left,
  Right,
}

pub fn tagged_union_interp<G1, G2>(((g1, g2), c): ((G1, G2), Choice)) -> Sum<G1, G2> {
  match c {
    Choice::Left => Sum::Inl(g1),
    Choice::Right => Sum::Inr(g2),
  }
}

pub fn tagged_union_t<T, C1, C2>(
  c1: C1,
  c2: C2,
) -> impl CrdtT<
  T,
  Op = Sum<Sum<C1::Op, C2::Op>, Choice>,
  State = ((C1::State, C2::State), HashSet<Event<T, Choice>>),
  Interp = Sum<C1::Interp, C2::Interp>,
>
where
  T: PartialOrd + Clone + Eq + Hash,
  C1: CrdtT<T, Op: Clone>,
  C2: CrdtT<T, Op: Clone>,
{
  map_interpretation(
    tagged_union_interp,
    disjoint_product(disjoint_product(c1, c2), mv_lww_t::<T, Choice>()),
  )
}

/// an operation on a side also makes that side active.
pub fn auto_tagged_union_t<T, C1, C2>(
  c1: C1,
  c2: C2,
) -> impl CrdtT<
  T,
  Op = Sum<C1::Op, C2::Op>,
  State = ((C1::State, C2::State), HashSet<Event<T, Choice>>),
  Interp = Sum<C1::Interp, C2::Interp>,
>
where
  T: PartialOrd + Clone + Eq + Hash,
  C1: CrdtT<T, Op: Clone>,
  C2: CrdtT<T, Op: Clone>,
{
  traverse(
    |o: &Sum<C1::Op, C2::Op>| match o {
      Sum::Inl(_) => vec![Sum::Inl(o.clone()), Sum::Inr(Choice::Left)],
      Sum::Inr(_) => vec![Sum::Inl(o.clone()), Sum::Inr(Choice::Right)],
    },
    tagged_union_t(c1, c2),
  )
}
