//! A user implementation that Verus rejects: subtraction is neither commutative nor associative,
//! so its `comm` and `assoc` obligations cannot be discharged and `ac_fun` cannot be built from it.
//!
//! `cargo verus verify --example rejected` is expected to FAIL.

use crdtlib_verus::ac_fun::{self, AcFun};
use vstd::prelude::*;

verus! {

pub struct Sub;

impl AcFun for Sub {
    type A = i64;

    open spec fn spec_f(a: i64, b: i64) -> i64 {
        ac_fun::wrap_i64(a - b)
    }

    fn f(a: &i64, b: &i64) -> (r: i64) {
        a.wrapping_sub(*b)
    }

    proof fn comm(a: i64, b: i64) {
    }

    proof fn assoc(a: i64, b: i64, c: i64) {
    }
}

fn main() {
}

} // verus!
