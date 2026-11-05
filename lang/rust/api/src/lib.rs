//! The CRDT traits shared by `crdtlib`, the native Rust combinators, and `crdtlib-bindings`, the
//! CRDTs compiled from the verified Lean definitions. A CRDT from either crate is a component of the
//! combinators in the other.
//!
//! Lean's `CRDT ω σ γ` and `CRDTₜ τ ω σ γ` become the traits [`Crdt`] and [`CrdtT`], which share
//! their types and interpretation through [`Datatype`]. The laws the Lean definitions prove are
//! obligations of the implementor here. They can be spot-checked with [`Crdt::commutes`] and
//! [`CrdtT::commutes_t`].

pub mod basic;
pub mod order;
pub mod sum;

pub use basic::{Crdt, CrdtT, Datatype, Event, Timed, concurrent};
pub use order::SemilatticeSup;
pub use sum::Sum;
