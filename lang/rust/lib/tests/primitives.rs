mod common;

use std::collections::{BTreeSet, HashSet};

use common::{apply, apply_t, assert_commutative, assert_commutative_t, vc};
use crdtlib::crdt::primitive::ac_fun::{counter, gcounter, max_int, union_set};
use crdtlib::crdt::primitive::constant::{const_zero, constant, constant_t};
use crdtlib::crdt::primitive::mv_reg::mv_reg_t;
use crdtlib::crdt::stdlib::lww::mv_lww_t;
use crdtlib::{CrdtT, Datatype, Event, concurrent};

#[test]
fn counter_sums() {
  let c = counter();
  let ops = [3, -5, 7, i64::MAX];
  assert_eq!(c.interpret(&apply(&c, &ops[..3], 0)), 5);
  assert_commutative(&c, &ops, &0);
  assert_commutative(&c, &ops, &i64::MIN);
}

#[test]
fn gcounter_sums() {
  let c = gcounter();
  assert_eq!(c.interpret(&apply(&c, &[1, 2, 3], 0)), 6);
  assert_commutative(&c, &[1, 2, u64::MAX], &4);
}

#[test]
fn max_int_keeps_the_max() {
  let c = max_int();
  assert_eq!(apply(&c, &[3, -5, 7, 1], i64::MIN), 7);
  assert_commutative(&c, &[3, -5, 7], &0);
}

#[test]
fn union_set_unions() {
  let c = union_set::<u8>();
  let ops = [
    BTreeSet::from([1, 2]),
    BTreeSet::from([2, 3]),
    BTreeSet::new(),
  ];
  assert_eq!(apply(&c, &ops, BTreeSet::new()), BTreeSet::from([1, 2, 3]));
  assert_commutative(&c, &ops, &BTreeSet::from([9]));
}

#[test]
fn constant_ignores_operations() {
  let c = constant::<i64, &str>();
  assert_eq!(c.interpret(&apply(&c, &[1, 2], "x")), "x");
  let ct = constant_t::<i64, &str>();
  assert_eq!(ct.effect_t(&vc(&[1]), &1, "x"), "x");

  let z = const_zero::<i64, &str, u32>();
  assert_eq!(z.interpret(&z.effect_t(&vc(&[1]), &1, "x")), 0);
}

#[test]
fn concurrent_is_incomparability() {
  assert!(concurrent(&vc(&[1, 0]), &vc(&[0, 1])));
  assert!(!concurrent(&vc(&[1, 0]), &vc(&[1, 1])));
  assert!(!concurrent(&vc(&[1, 1]), &vc(&[1, 1])));
}

#[test]
fn mv_reg_keeps_concurrent_writes() {
  let c = mv_reg_t();
  let a = (vc(&[1, 0]), 'a');
  let b = (vc(&[0, 1]), 'b');
  let s = apply_t(&c, &[a.clone(), b.clone()], HashSet::new());
  assert_eq!(
    s,
    HashSet::from([
      Event {
        t: a.0.clone(),
        o: 'a'
      },
      Event {
        t: b.0.clone(),
        o: 'b'
      }
    ])
  );

  // A write that has seen both replaces them.
  let s = c.effect_t(&vc(&[1, 1]), &'c', s);
  assert_eq!(
    s,
    HashSet::from([Event {
      t: vc(&[1, 1]),
      o: 'c'
    }])
  );

  assert_commutative_t(&c, &[a, b, (vc(&[2, 0]), 'd')], &HashSet::new());
}

#[test]
fn mv_lww_resolves_to_the_max() {
  let c = mv_lww_t();
  assert_eq!(c.interpret(&HashSet::new()), 0);
  let s = apply_t(&c, &[(vc(&[1, 0]), 7), (vc(&[0, 1]), 3)], HashSet::new());
  assert_eq!(c.interpret(&s), 7);
  let s = c.effect_t(&vc(&[2, 1]), &1, s);
  assert_eq!(c.interpret(&s), 1);
}
