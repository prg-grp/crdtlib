mod common;

use std::collections::{HashMap, HashSet};

use common::{apply, apply_t, assert_commutative, assert_commutative_t, vc};
use crdtlib::combinator::derived::disjoint_product::disjoint_product;
use crdtlib::combinator::derived::joint_product::joint_product;
use crdtlib::combinator::derived::map_op::map_op;
use crdtlib::combinator::derived::tagged_union::{Choice, auto_tagged_union_t, tagged_union_t};
use crdtlib::combinator::principal::associate::associate;
use crdtlib::combinator::principal::map_interpretation::map_interpretation;
use crdtlib::combinator::principal::map_state::map_state;
use crdtlib::combinator::principal::product::{product, product3};
use crdtlib::combinator::principal::traverse::{
  traverse, traverse_list, traverse_mapop, traverse_rec,
};
use crdtlib::crdt::primitive::ac_fun::{counter, max_int};
use crdtlib::{Crdt, CrdtT, Datatype, Sum};

#[test]
fn product_sends_every_operation_to_both() {
  let c = product(counter(), max_int());
  let s = apply(&c, &[3, -5, 7], (0, i64::MIN));
  assert_eq!(c.interpret(&s), (5, 7));
  assert_commutative(&c, &[3, -5, 7], &(1, 2));

  let c3 = product3(counter(), max_int(), counter());
  assert_eq!(c3.interpret(&apply(&c3, &[2, 4], ((0, 0), 1))), ((6, 4), 7));
}

#[test]
fn map_interpretation_post_composes() {
  let c = map_interpretation(|x: i64| x.is_positive(), counter());
  assert!(!c.interpret(&apply(&c, &[3, -5], 0)));
  assert!(c.interpret(&apply(&c, &[3, -1], 0)));
}

#[test]
fn map_state_changes_the_representation() {
  let c = map_state(
    |x: i64| x.to_string(),
    |s: String| s.parse().unwrap(),
    counter(),
  );
  let s = apply(&c, &[3, -5, 7], "0".to_string());
  assert_eq!(s, "5");
  assert_eq!(c.interpret(&s), 5);
  assert_commutative(&c, &[3, -5, 7], &"10".to_string());
}

#[test]
fn traverse_applies_every_operation() {
  // `n` increments by `1`, `n` times.
  let unary = |n: &u8| vec![1; *n as usize];
  let c = traverse(unary, counter());
  assert_eq!(c.interpret(&apply(&c, &[3, 0, 2], 0)), 5);
  assert_commutative(&c, &[3, 0, 2], &0);

  let c = traverse_list(unary, counter());
  assert_eq!(c.interpret(&apply(&c, &[3, 0, 2], 0)), 5);

  let c = traverse_mapop(|n: &u8| *n as i64, counter());
  assert_eq!(c.interpret(&apply(&c, &[3, 0, 2], 0)), 5);

  // Count down from `n`, emitting each step.
  let c = traverse_rec(
    |n: &u8| *n,
    |n: u8| (n > 0).then(|| (n as i64, n - 1)),
    counter(),
  );
  assert_eq!(c.interpret(&apply(&c, &[3, 2], 0)), 6 + 3);
}

#[test]
fn traverse_is_timed_when_its_component_is() {
  let c = traverse(|n: &u8| vec![1; *n as usize], counter().timed());
  assert_eq!(apply_t(&c, &[(vc(&[1, 0]), 2), (vc(&[0, 1]), 3)], 0), 5);
}

#[test]
fn associate_keeps_one_component_per_key() {
  let c = associate::<&str, _>(counter());
  let ops = [("a", 1), ("b", 2), ("a", 3), ("c", -1)];
  let s = apply(&c, &ops, HashMap::new());
  let i = c.interpret(&s);
  assert_eq!(*i.map(&"a"), 4);
  assert_eq!(*i.map(&"b"), 2);
  assert_eq!(*i.map(&"z"), 0);
  assert_eq!(i.to_list(), vec![(&"a", &4), (&"b", &2), (&"c", &-1)]);
  assert_commutative(&c, &ops, &s);
}

#[test]
fn associate_is_timed_when_its_component_is() {
  let c = associate::<char, _>(counter().timed());
  let s = apply_t(
    &c,
    &[(vc(&[1, 0]), ('x', 2)), (vc(&[0, 1]), ('x', 3))],
    HashMap::new(),
  );
  assert_eq!(*c.interpret(&s).map(&'x'), 5);
}

#[test]
fn map_op_translates_operations() {
  let c = map_op(|b: &bool| if *b { 1 } else { -1 }, counter());
  assert_eq!(c.interpret(&apply(&c, &[true, true, false], 0)), 1);
}

#[test]
fn disjoint_product_routes_by_side() {
  let c = disjoint_product(counter(), max_int());
  let ops = [Sum::Inl(3), Sum::Inr(7), Sum::Inl(-1), Sum::Inr(2)];
  assert_eq!(c.interpret(&apply(&c, &ops, (0, 0))), (2, 7));
  assert_commutative(&c, &ops, &(0, 0));
}

#[test]
fn joint_product_splits_pairs() {
  let c = joint_product(counter(), max_int());
  let ops = [(3, 7), (-1, 2)];
  assert_eq!(c.interpret(&apply(&c, &ops, (0, 0))), (2, 7));
  assert_commutative(&c, &ops, &(0, 0));
}

#[test]
fn tagged_union_follows_the_last_choice() {
  let c = tagged_union_t(counter().timed(), max_int().timed());
  let s0 = ((0, 0), HashSet::new());
  assert_eq!(c.interpret(&s0), Sum::Inl(0));

  let evs = [
    (vc(&[1, 0]), Sum::Inl(Sum::Inl(3))),
    (vc(&[2, 0]), Sum::Inr(Choice::Left)),
    (vc(&[0, 1]), Sum::Inl(Sum::Inr(9))),
    (vc(&[0, 2]), Sum::Inr(Choice::Right)),
  ];
  // Concurrent choices resolve to `right`.
  let s = apply_t(&c, &evs, s0.clone());
  assert_eq!(c.interpret(&s), Sum::Inr(9));
  assert_commutative_t(&c, &evs, &s0);

  // A choice that has seen both wins.
  let s = c.effect_t(&vc(&[3, 2]), &Sum::Inr(Choice::Left), s);
  assert_eq!(c.interpret(&s), Sum::Inl(3));
}

#[test]
fn auto_tagged_union_activates_the_side_it_updates() {
  let c = auto_tagged_union_t(counter().timed(), max_int().timed());
  let s = apply_t(
    &c,
    &[(vc(&[1, 0]), Sum::Inl(3)), (vc(&[1, 1]), Sum::Inr(9))],
    ((0, 0), HashSet::new()),
  );
  assert_eq!(c.interpret(&s), Sum::Inr(9));
  let s = c.effect_t(&vc(&[2, 1]), &Sum::Inl(1), s);
  assert_eq!(c.interpret(&s), Sum::Inl(4));
}
