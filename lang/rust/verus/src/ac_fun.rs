//! Verified `ac_fun`: a user supplies `f` with proofs that it is commutative and associative
//! (Lean's `Std.Commutative f` and `Std.Associative f`), and Verus derives the CRDT law
//! `commutative` for `ac_fun f`, as `ac_fun` does in `Crdtlib/CRDT/Primitive/ACFun.lean`.
//!
//! Check with `cargo verus verify`. Verified with Verus 0.2026.10.26.d17fbd0 (release binary from
//! github.com/verus-lang/verus, which needs the rustup toolchain 1.99.1).

use vstd::prelude::*;

verus! {

/// `CRDT ω σ γ`: the effects and the interpretation as spec functions, the `commutative` law as a
/// lemma every implementation must prove.
pub trait Crdt {
    type Op;
    type State;
    type Interp;

    spec fn effect(op: Self::Op, state: Self::State) -> Self::State;

    spec fn interpret(state: Self::State) -> Self::Interp;

    proof fn commutative(e1: Self::Op, e2: Self::Op, s: Self::State)
        ensures
            Self::effect(e2, Self::effect(e1, s)) == Self::effect(e1, Self::effect(e2, s)),
    ;
}

pub trait AcFun {
    type A;

    spec fn spec_f(a: Self::A, b: Self::A) -> Self::A;

    fn f(a: &Self::A, b: &Self::A) -> (r: Self::A)
        ensures
            r == Self::spec_f(*a, *b),
    ;

    proof fn comm(a: Self::A, b: Self::A)
        ensures
            Self::spec_f(a, b) == Self::spec_f(b, a),
    ;

    proof fn assoc(a: Self::A, b: Self::A, c: Self::A)
        ensures
            Self::spec_f(Self::spec_f(a, b), c) == Self::spec_f(a, Self::spec_f(b, c)),
    ;
}

/// `ac_fun α f`
pub struct AcFunCrdt<F>(F);

impl<F: AcFun> Crdt for AcFunCrdt<F> {
    type Op = F::A;
    type State = F::A;
    type Interp = F::A;

    open spec fn effect(op: F::A, state: F::A) -> F::A {
        F::spec_f(op, state)
    }

    open spec fn interpret(state: F::A) -> F::A {
        state
    }

    /// `f e₂ (f e₁ s) = f (f e₂ e₁) s = f (f e₁ e₂) s = f e₁ (f e₂ s)`
    proof fn commutative(e1: F::A, e2: F::A, s: F::A) {
        F::assoc(e2, e1, s);
        F::comm(e2, e1);
        F::assoc(e1, e2, s);
    }
}

impl<F: AcFun> AcFunCrdt<F> {
    pub fn exec_effect(op: &F::A, state: F::A) -> (r: F::A)
        ensures
            r == <Self as Crdt>::effect(*op, state),
    {
        F::f(op, &state)
    }
}

// Instances from `ACFun.lean`.

/// `x` modulo `2^64`, in the range of `i64`: the result of `wrapping_add` on `i64`.
pub open spec fn wrap_i64(x: int) -> i64 {
    if x > i64::MAX {
        (x - 0x1_0000_0000_0000_0000) as i64
    } else if x < i64::MIN {
        (x + 0x1_0000_0000_0000_0000) as i64
    } else {
        x as i64
    }
}

/// `x` modulo `2^64`, in the range of `u64`: the result of `wrapping_add` on `u64`.
pub open spec fn wrap_u64(x: int) -> u64 {
    if x > u64::MAX {
        (x - 0x1_0000_0000_0000_0000) as u64
    } else {
        x as u64
    }
}

/// `counter`, over `i64` with wrapping addition.
pub struct Counter;

impl AcFun for Counter {
    type A = i64;

    open spec fn spec_f(a: i64, b: i64) -> i64 {
        wrap_i64(a + b)
    }

    fn f(a: &i64, b: &i64) -> (r: i64) {
        a.wrapping_add(*b)
    }

    proof fn comm(a: i64, b: i64) {
    }

    proof fn assoc(a: i64, b: i64, c: i64) {
    }
}

/// `gcounter`, over `u64` with wrapping addition.
pub struct GCounter;

impl AcFun for GCounter {
    type A = u64;

    open spec fn spec_f(a: u64, b: u64) -> u64 {
        wrap_u64(a + b)
    }

    fn f(a: &u64, b: &u64) -> (r: u64) {
        a.wrapping_add(*b)
    }

    proof fn comm(a: u64, b: u64) {
    }

    proof fn assoc(a: u64, b: u64, c: u64) {
    }
}

/// `max_int`: `join` on `i64`.
pub struct MaxInt;

impl AcFun for MaxInt {
    type A = i64;

    open spec fn spec_f(a: i64, b: i64) -> i64 {
        if a >= b { a } else { b }
    }

    fn f(a: &i64, b: &i64) -> (r: i64) {
        if *a >= *b { *a } else { *b }
    }

    proof fn comm(a: i64, b: i64) {
    }

    proof fn assoc(a: i64, b: i64, c: i64) {
    }
}

/// A user implementation: bitwise or, a join on `u64` that `ACFun.lean` does not list.
pub struct BitOr;

impl AcFun for BitOr {
    type A = u64;

    open spec fn spec_f(a: u64, b: u64) -> u64 {
        a | b
    }

    fn f(a: &u64, b: &u64) -> (r: u64) {
        *a | *b
    }

    proof fn comm(a: u64, b: u64) {
        assert(a | b == b | a) by (bit_vector);
    }

    proof fn assoc(a: u64, b: u64, c: u64) {
        assert((a | b) | c == a | (b | c)) by (bit_vector);
    }
}

/// The derived law at a concrete instance.
proof fn counter_commutes(e1: i64, e2: i64, s: i64)
    ensures
        <AcFunCrdt<Counter> as Crdt>::effect(e2, <AcFunCrdt<Counter> as Crdt>::effect(e1, s))
            == <AcFunCrdt<Counter> as Crdt>::effect(e1, <AcFunCrdt<Counter> as Crdt>::effect(e2, s)),
{
    AcFunCrdt::<Counter>::commutative(e1, e2, s);
}

/// The executable effect agrees with its specification.
fn counter_example() {
    let s = AcFunCrdt::<Counter>::exec_effect(&3, 0);
    let s = AcFunCrdt::<Counter>::exec_effect(&-5, s);
    assert(s == -2);
}

} // verus!
