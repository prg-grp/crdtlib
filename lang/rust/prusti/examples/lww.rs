//! The last-writer-wins register of `verus/examples/lww.rs` in Prusti: the state is the latest
//! `(timestamp, value)` write, and ties are broken by the value.
//!
//! `cargo prusti --example lww` passes. Dropping the tie-breaker in `f`, i.e.
//! `if a.0 >= b.0 { a } else { b }`, makes `comm` fail. There is no separate spec to keep in sync:
//! the laws are stated about the pure `f` itself.

// Lemma arguments only appear in the lemmas' specs.
#![allow(unused_variables)]

use crdtlib_prusti::ac_fun::{AcFunPair, Pair};
use prusti_contracts::*;

pub struct Lww;

#[refine_trait_spec]
impl AcFunPair for Lww {
    #[pure]
    fn f(a: Pair, b: Pair) -> Pair {
        if a.0 > b.0 || (a.0 == b.0 && a.1 >= b.1) {
            a
        } else {
            b
        }
    }

    fn comm(a: Pair, b: Pair) {}

    fn assoc(a: Pair, b: Pair, c: Pair) {}
}

fn main() {
    // Two concurrent writes with the same timestamp: the greater value wins in either order.
    let s = Lww::f((1, 7), (0, 0));
    let s = Lww::f((1, 9), s);
    prusti_assert!(s === (1, 9));
}
