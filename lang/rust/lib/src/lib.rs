//! Native Rust implementation of the crdtlib primitives and combinators. The module tree mirrors
//! `Crdtlib/`. The traits come from `crdtlib-api` and are re-exported here, so a CRDT from
//! `crdtlib-bindings` is also a component of every combinator.
//!
//! Every combinator is a single struct that is a [`Crdt`] when its components are, and a [`CrdtT`]
//! when its components are, so `product` and `productₜ` (and so on) are the same Rust function.
//!
//! The laws the Lean definitions prove (commutativity, `f' ∘ f = id` for `map_state`,
//! associativity and commutativity for `ac_fun`) are obligations of the caller here. They can be
//! spot-checked with [`Crdt::commutes`] and [`CrdtT::commutes_t`].
//!
//! | Lean                                  | Rust                                              |
//! |---------------------------------------|---------------------------------------------------|
//! | `ac_fun`, `counter`, `gcounter`, ...  | [`crdt::primitive::ac_fun`]                       |
//! | `const`, `constₜ`, `const_zero`       | [`crdt::primitive::constant`]                     |
//! | `mv_regₜ`                             | [`crdt::primitive::mv_reg`]                       |
//! | `mv_lwwₜ`                             | [`crdt::stdlib::lww`]                             |
//! | `product`, `product3`                 | [`combinator::principal::product`]                |
//! | `map_interpretation`                  | [`combinator::principal::map_interpretation`]     |
//! | `map_state`                           | [`combinator::principal::map_state`]              |
//! | `traverse`, `traverse_rec`, ...       | [`combinator::principal::traverse`]               |
//! | `associate`                           | [`combinator::principal::associate`]              |
//! | `map_op`                              | [`combinator::derived::map_op`]                   |
//! | `disjoint_product`                    | [`combinator::derived::disjoint_product`]         |
//! | `joint_product`                       | [`combinator::derived::joint_product`]            |
//! | `tagged_unionₜ`, `auto_tagged_unionₜ` | [`combinator::derived::tagged_union`]             |

// Combinator types nest by construction.
#![allow(clippy::type_complexity)]

pub mod combinator;
pub mod crdt;

pub use crdtlib_api::*;
