use std::collections::HashSet;
use std::hash::Hash;

use crate::combinator::derived::disjoint_product::disjoint_product;
use crate::combinator::principal::map_interpretation::map_interpretation;
use crate::combinator::principal::map_state::map_state;
use crate::combinator::principal::traverse::traverse;
use crate::crdt::stdlib::lww::mv_lww_t;
use crdtlib_api::{CrdtT, Event, Sum};

/// `Choice`: which side of a tagged union is active. `0` is `left`.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Choice {
  #[default]
  Left,
  Right,
}

/// `tagged_union_interp`
pub fn tagged_union_interp<G1, G2>(((g1, g2), c): ((G1, G2), Choice)) -> Sum<G1, G2> {
  match c {
    Choice::Left => Sum::Inl(g1),
    Choice::Right => Sum::Inr(g2),
  }
}

/// `tagged_unionₜ c₁ c₂`: both components side by side, and a multi-value LWW register choosing
/// the active one. Concurrent choices resolve to `right`.
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

/// `auto_tagged_unionₜ c₁ c₂`: an operation on one side also makes that side active.
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

/// `tagged_union_3 c₁ c₂ c₃`: `tagged_unionₜ (tagged_unionₜ c₁ c₂) c₃` with its state flattened.
pub fn tagged_union_3<T, C1, C2, C3>(
  c1: C1,
  c2: C2,
  c3: C3,
) -> impl CrdtT<
  T,
  Op = Sum<Sum<Sum<Sum<C1::Op, C2::Op>, Choice>, C3::Op>, Choice>,
  State = (
    (C1::State, C2::State, C3::State),
    HashSet<Event<T, Choice>>,
    HashSet<Event<T, Choice>>,
  ),
  Interp = Sum<Sum<C1::Interp, C2::Interp>, C3::Interp>,
>
where
  T: PartialOrd + Clone + Eq + Hash,
  C1: CrdtT<T, Op: Clone, State: Clone>,
  C2: CrdtT<T, Op: Clone, State: Clone>,
  C3: CrdtT<T, Op: Clone, State: Clone>,
{
  map_state(
    |((((s1, s2), inner), s3), outer)| ((s1, s2, s3), inner, outer),
    |((s1, s2, s3), inner, outer)| ((((s1, s2), inner), s3), outer),
    tagged_union_t(tagged_union_t(c1, c2), c3),
  )
}
