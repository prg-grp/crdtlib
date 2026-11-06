//! A user implementation that Prusti rejects: keeping the left argument is associative but not
//! commutative, so its `comm` lemma cannot be proved and `ac_fun` cannot be built from it.
//!
//! `cargo prusti --example rejected` is expected to FAIL.

// Lemma arguments only appear in the lemmas' specs.
#![allow(unused_variables)]

use crdtlib_prusti::ac_fun::AcFunI64;
use prusti_contracts::*;

pub struct Left;

#[refine_trait_spec]
impl AcFunI64 for Left {
    #[pure]
    fn f(a: i64, _b: i64) -> i64 {
        a
    }

    fn comm(a: i64, b: i64) {}

    fn assoc(a: i64, b: i64, c: i64) {}
}

fn main() {}
