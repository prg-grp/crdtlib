//! Verified `map_state`: a user supplies `f` and `f'` with a proof that `f'` is a left inverse of
//! `f` (Lean's `f' ∘ f = id`), and Verus derives the CRDT law `commutative` for `map_state f f' c`
//! from that of `c`, as `map_state` does in `Crdtlib/Combinator/Principal/MapState.lean`.
//!
//! Check with `cargo verus verify`.

use vstd::prelude::*;

use crate::ac_fun::{AcFunCrdt, Crdt, GCounter};

verus! {

/// The arguments `f`, `f'` and `i : f' ∘ f = id` of `map_state`. Only a left inverse is required:
/// `f` need not be onto, so the new state type can be larger than the old one.
pub trait LeftInverse {
    type From;
    type To;

    spec fn spec_f(x: Self::From) -> Self::To;

    spec fn spec_f_inv(y: Self::To) -> Self::From;

    fn f(x: Self::From) -> (r: Self::To)
        ensures
            r == Self::spec_f(x),
    ;

    fn f_inv(y: Self::To) -> (r: Self::From)
        ensures
            r == Self::spec_f_inv(y),
    ;

    proof fn left_inverse(x: Self::From)
        ensures
            Self::spec_f_inv(Self::spec_f(x)) == x,
    ;
}

/// `map_state f f' c`: stores `c`'s state as `f` of it.
pub struct MapState<I, C>(I, C);

impl<I: LeftInverse, C: Crdt<State = I::From>> Crdt for MapState<I, C> {
    type Op = C::Op;
    type State = I::To;
    type Interp = C::Interp;

    open spec fn effect(op: C::Op, state: I::To) -> I::To {
        I::spec_f(C::effect(op, I::spec_f_inv(state)))
    }

    open spec fn interpret(state: I::To) -> C::Interp {
        C::interpret(I::spec_f_inv(state))
    }

    /// With `x = f' s`: `f (c₂ (f' (f (c₁ x)))) = f (c₂ (c₁ x)) = f (c₁ (c₂ x)) = f (c₁ (f' (f (c₂ x))))`
    proof fn commutative(e1: C::Op, e2: C::Op, s: I::To) {
        let x = I::spec_f_inv(s);
        I::left_inverse(C::effect(e1, x));
        I::left_inverse(C::effect(e2, x));
        C::commutative(e1, e2, x);
    }
}

/// A user implementation: widen a `u64` to a `u128`. Narrowing back is a left inverse, though not a
/// right one, since most `u128`s are out of range.
pub struct Widen;

impl LeftInverse for Widen {
    type From = u64;
    type To = u128;

    open spec fn spec_f(x: u64) -> u128 {
        x as u128
    }

    open spec fn spec_f_inv(y: u128) -> u64 {
        y as u64
    }

    fn f(x: u64) -> (r: u128) {
        x as u128
    }

    fn f_inv(y: u128) -> (r: u64) {
        y as u64
    }

    proof fn left_inverse(x: u64) {
    }
}

/// The derived law at a concrete instance: `gcounter` with its state stored as a `u128`.
proof fn widened_gcounter_commutes(e1: u64, e2: u64, s: u128)
    ensures
        <MapState<Widen, AcFunCrdt<GCounter>> as Crdt>::effect(
            e2,
            <MapState<Widen, AcFunCrdt<GCounter>> as Crdt>::effect(e1, s),
        ) == <MapState<Widen, AcFunCrdt<GCounter>> as Crdt>::effect(
            e1,
            <MapState<Widen, AcFunCrdt<GCounter>> as Crdt>::effect(e2, s),
        ),
{
    MapState::<Widen, AcFunCrdt<GCounter>>::commutative(e1, e2, s);
}

} // verus!
