//! A user implementation that Verus rejects: narrowing a `u128` to a `u64` loses the high bits, so
//! widening back is not a left inverse, its `left_inverse` obligation cannot be discharged, and
//! `map_state` cannot be built from it.
//!
//! `cargo verus verify --example rejected_map_state` is expected to FAIL.

use crdtlib_verus::map_state::LeftInverse;
use vstd::prelude::*;

verus! {

pub struct Narrow;

impl LeftInverse for Narrow {
    type From = u128;
    type To = u64;

    open spec fn spec_f(x: u128) -> u64 {
        x as u64
    }

    open spec fn spec_f_inv(y: u64) -> u128 {
        y as u128
    }

    fn f(x: u128) -> (r: u64) {
        x as u64
    }

    fn f_inv(y: u64) -> (r: u128) {
        y as u128
    }

    proof fn left_inverse(x: u128) {
    }
}

fn main() {
}

} // verus!
