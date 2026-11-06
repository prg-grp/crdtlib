//! Verified `map_state`, as in `verus/src/map_state.rs`: a user supplies `f` and `f'` with a proof
//! that `f'` is a left inverse of `f`, and Prusti derives the CRDT law `commutative` for
//! `map_state f f' c` from that of `c`, whose effect `e` on the state `s` is `f (c e (f' s))`.
//!
//! As in `ac_fun.rs`, the state types are fixed per trait: the component's state is `i64` and the
//! stored state is `Tagged`.

use prusti_contracts::*;

use crate::ac_fun::{AcFunI64, MaxInt, commutative_i64};

/// A CRDT with `i64` operations and states: a pure effect and the law `commutative`, as a lemma.
pub trait CrdtI64 {
    #[pure]
    fn effect(op: i64, s: i64) -> i64;

    #[ensures(Self::effect(e2, Self::effect(e1, s)) === Self::effect(e1, Self::effect(e2, s)))]
    fn commutative(e1: i64, e2: i64, s: i64);
}

/// An `i64` with a tag, e.g. a version that a `LeftInverseI64` sets.
pub type Tagged = (i64, u64);

/// The arguments `f`, `f'` and `i : f' ∘ f = id` of `map_state`, from `i64` to `Tagged`. Only a
/// left inverse is required: `f` need not be onto.
pub trait LeftInverseI64 {
    #[pure]
    fn f(x: i64) -> Tagged;

    #[pure]
    fn f_inv(y: Tagged) -> i64;

    #[ensures(Self::f_inv(Self::f(x)) === x)]
    fn left_inverse(x: i64);
}

/// `commutative` of `map_state f f' c`, written out since Prusti's specs take no turbofish with
/// several types. With `x = f' s`:
/// `f (c₂ (f' (f (c₁ x)))) = f (c₂ (c₁ x)) = f (c₁ (c₂ x)) = f (c₁ (f' (f (c₂ x))))`.
#[ensures(
    I::f(C::effect(e2, I::f_inv(I::f(C::effect(e1, I::f_inv(s))))))
        === I::f(C::effect(e1, I::f_inv(I::f(C::effect(e2, I::f_inv(s))))))
)]
pub fn map_state_commutative<I: LeftInverseI64, C: CrdtI64>(e1: i64, e2: i64, s: Tagged) {
    let x = I::f_inv(s);
    I::left_inverse(C::effect(e1, x));
    I::left_inverse(C::effect(e2, x));
    C::commutative(e1, e2, x);
}

/// `max_int` as a `CrdtI64`.
#[refine_trait_spec]
impl CrdtI64 for MaxInt {
    #[pure]
    fn effect(op: i64, s: i64) -> i64 {
        <MaxInt as AcFunI64>::f(op, s)
    }

    fn commutative(e1: i64, e2: i64, s: i64) {
        commutative_i64::<MaxInt>(e1, e2, s);
    }
}

/// A user implementation: store the state with the tag `0`, and drop the tag to read it back.
pub struct Untagged;

#[refine_trait_spec]
impl LeftInverseI64 for Untagged {
    #[pure]
    fn f(x: i64) -> Tagged {
        (x, 0)
    }

    #[pure]
    fn f_inv(y: Tagged) -> i64 {
        y.0
    }

    fn left_inverse(x: i64) {}
}

/// `map_state` of `max_int` with `Untagged`: its effects commute.
#[ensures(
    Untagged::f(MaxInt::effect(e2, Untagged::f_inv(Untagged::f(MaxInt::effect(e1, Untagged::f_inv(s))))))
        === Untagged::f(MaxInt::effect(e1, Untagged::f_inv(Untagged::f(MaxInt::effect(e2, Untagged::f_inv(s))))))
)]
pub fn untagged_max_int_commutes(e1: i64, e2: i64, s: Tagged) {
    map_state_commutative::<Untagged, MaxInt>(e1, e2, s);
}
