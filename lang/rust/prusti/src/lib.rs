//! Prusti proofs for `lang/rust/lib`. `cargo prusti` verifies the crate and, as configured in
//! `Prusti.toml`, then builds it into `target/verify`; a failed proof fails the build.

// Lemma arguments only appear in the lemmas' specs.
#![allow(unused_variables)]

pub mod ac_fun;
pub mod map_state;
