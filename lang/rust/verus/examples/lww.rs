//! A last-writer-wins register as an `ac_fun`: the state is the latest `(timestamp, value)` write.
//! Concurrent writes can carry the same timestamp, so ties are broken by the value, as `Lamport`
//! does in `Crdtlib/CRDT/Std/LWW/LWW.lean`.
//!
//! `cargo verus verify --example lww` passes. Dropping the tie-breaker, i.e. comparing only the
//! timestamps in `later` and `f`, makes `comm` fail: of two writes with the same timestamp, `f`
//! then keeps whichever comes first.

use crdtlib_verus::ac_fun::{AcFun, AcFunCrdt};
use vstd::prelude::*;

verus! {

/// `(timestamp, value)`
pub type Write = (u64, u64);

/// `a` is at least as late as `b`.
pub open spec fn later(a: Write, b: Write) -> bool {
    a.0 > b.0 || (a.0 == b.0 && a.1 >= b.1)
}

pub struct Lww;

impl AcFun for Lww {
    type A = Write;

    open spec fn spec_f(a: Write, b: Write) -> Write {
        if later(a, b) { a } else { b }
    }

    fn f(a: &Write, b: &Write) -> (r: Write) {
        if a.0 > b.0 || (a.0 == b.0 && a.1 >= b.1) { *a } else { *b }
    }

    proof fn comm(a: Write, b: Write) {
    }

    proof fn assoc(a: Write, b: Write, c: Write) {
    }
}

fn main() {
    // Two concurrent writes with the same timestamp: the greater value wins in either order.
    let s = AcFunCrdt::<Lww>::exec_effect(&(1, 7), (0, 0));
    let s = AcFunCrdt::<Lww>::exec_effect(&(1, 9), s);
    assert(s == (1u64, 9u64));
}

} // verus!
