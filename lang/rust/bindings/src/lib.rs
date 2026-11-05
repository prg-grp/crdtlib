//! The verified crdtlib CRDTs, compiled from `Crdtlib/` by Lean and linked as shared libraries.
//! Each implements the `crdtlib-api` traits, so it is also a component of the native combinators in
//! `crdtlib`. Call [`init`] once before using any of them.

pub mod crdt;
mod lean_rt;

pub use lean_rt::init;
