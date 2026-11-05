use std::collections::HashSet;
use std::hash::Hash;

use crate::combinator::principal::map_interpretation::{MapInterpretation, map_interpretation};
use crate::crdt::primitive::mv_reg::{MvReg, mv_reg_t};
use crdtlib_api::Event;

/// `mv_lwwₜ σ`: a multi-value register that resolves concurrent writes to the greatest value, and
/// reads `0` before the first write.
pub fn mv_lww_t<T, O>() -> MapInterpretation<MvReg<T, O>, impl Fn(HashSet<Event<T, O>>) -> O>
where
  T: Clone + Eq + Hash,
  O: Ord + Default + Clone + Eq + Hash,
{
  map_interpretation(
    |s: HashSet<Event<T, O>>| s.into_iter().map(|e| e.o).max().unwrap_or_default(),
    mv_reg_t(),
  )
}
