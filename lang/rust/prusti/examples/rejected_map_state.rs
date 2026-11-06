//! A user implementation that Prusti rejects: storing every state as `(0, 0)` forgets it, so
//! dropping the tag is not a left inverse, its `left_inverse` lemma cannot be proved, and
//! `map_state` cannot be built from it.
//!
//! `cargo prusti --example rejected_map_state` is expected to FAIL.

// Lemma arguments only appear in the lemmas' specs.
#![allow(unused_variables)]

use crdtlib_prusti::map_state::{LeftInverseI64, Tagged};
use prusti_contracts::*;

pub struct Forget;

#[refine_trait_spec]
impl LeftInverseI64 for Forget {
    #[pure]
    fn f(x: i64) -> Tagged {
        (0, 0)
    }

    #[pure]
    fn f_inv(y: Tagged) -> i64 {
        y.0
    }

    fn left_inverse(x: i64) {}
}

fn main() {}
