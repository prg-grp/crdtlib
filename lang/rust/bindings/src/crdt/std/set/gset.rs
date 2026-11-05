use crdtlib_api::{Crdt, Datatype};

use crate::lean_rt::{LeanObj, lean_dec_ref, lean_inc_ref};

mod ffi {
  use crate::lean_rt::LeanObj;
  unsafe extern "C" {
    pub static gset_empty_u64: LeanObj;
    pub fn gset_effect_u64(event: u64, state: LeanObj) -> LeanObj;
    pub fn gset_interpret_mem_u64(key: u64, state: LeanObj) -> u8;
  }
}

/// An owned reference to a Lean object. The exported Lean functions take their arguments owned,
/// so every call passes a fresh reference.
struct Owned(LeanObj);

impl Owned {
  fn share(&self) -> LeanObj {
    lean_inc_ref(self.0);
    self.0
  }
}

impl Clone for Owned {
  fn clone(&self) -> Self {
    Owned(self.share())
  }
}

impl Drop for Owned {
  fn drop(&mut self) {
    lean_dec_ref(self.0);
  }
}

/// `GSet UInt64`
#[derive(Clone)]
pub struct GSetState(Owned);

impl Default for GSetState {
  /// `0`, the empty set.
  fn default() -> Self {
    unsafe {
      lean_inc_ref(ffi::gset_empty_u64);
      GSetState(Owned(ffi::gset_empty_u64))
    }
  }
}

/// `SetInterp UInt64`
#[derive(Clone)]
pub struct GSetInterp(Owned);

impl GSetInterp {
  pub fn mem(&self, key: u64) -> bool {
    unsafe { ffi::gset_interpret_mem_u64(key, self.0.share()) != 0 }
  }
}

/// `gset UInt64`: a grow-only set.
#[derive(Clone, Copy, Debug, Default)]
pub struct LeanGSet;

impl Datatype for LeanGSet {
  type Op = u64;
  type State = GSetState;
  type Interp = GSetInterp;

  fn interpret(&self, state: &GSetState) -> GSetInterp {
    GSetInterp(state.0.clone())
  }
}

impl Crdt for LeanGSet {
  fn effect(&self, op: &u64, state: GSetState) -> GSetState {
    let raw = state.0.0;
    std::mem::forget(state);
    GSetState(Owned(unsafe { ffi::gset_effect_u64(*op, raw) }))
  }
}
