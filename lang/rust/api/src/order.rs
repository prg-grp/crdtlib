use std::collections::{BTreeSet, HashSet};
use std::hash::Hash;

pub trait SemilatticeSup {
  fn sup(&self, other: &Self) -> Self;
}

macro_rules! sup_by_max {
  ($($t:ty),*) => {
    $(impl SemilatticeSup for $t {
      fn sup(&self, other: &Self) -> Self {
        *self.max(other)
      }
    })*
  };
}

sup_by_max!(
  bool, u8, u16, u32, u64, u128, usize, i8, i16, i32, i64, i128, isize
);

impl<A: Ord + Clone> SemilatticeSup for BTreeSet<A> {
  fn sup(&self, other: &Self) -> Self {
    self.union(other).cloned().collect()
  }
}

impl<A: Eq + Hash + Clone> SemilatticeSup for HashSet<A> {
  fn sup(&self, other: &Self) -> Self {
    self.union(other).cloned().collect()
  }
}
