use crate::crdt::basic::Crdt;
use crate::lean_rt::{LeanObj, lean_dec_ref, lean_inc_ref};
use std::marker::PhantomData;

mod ffi {
  use crate::lean_rt::LeanObj;
  unsafe extern "C" {
    pub static gset_empty_u64: LeanObj;
    pub fn gset_effect_u64(event: u64, state: LeanObj) -> LeanObj;
    pub fn gset_interpret_mem_u64(key: u64, state: LeanObj) -> u8;
  }
}

pub struct GSetState(LeanObj);

impl Clone for GSetState {
  fn clone(&self) -> Self {
    lean_inc_ref(self.0);
    GSetState(self.0)
  }
}

impl Drop for GSetState {
  fn drop(&mut self) {
    lean_dec_ref(self.0);
  }
}

unsafe impl Send for GSet {}
unsafe impl Sync for GSet {}

pub struct GSetInterp<T>(LeanObj, PhantomData<T>);

impl GSetInterp<u64> {
  pub fn mem(&self, key: u64) -> bool {
    unsafe {
      lean_inc_ref(self.0);
      ffi::gset_interpret_mem_u64(key, self.0) != 0
    }
  }
}

pub trait GSet:
  Crdt<Op = u64, State = GSet, Interp = GSetInterp<u64>>
{
}

pub struct LeanGSet;

impl Crdt for LeanGSet {
  type Op = u64;
  type State = GSet;
  type Interp = GSetInterp<u64>;

  fn effect(event: u64, state: GSet) -> GSet {
    let raw = state.0;
    std::mem::forget(state);
    GSet(unsafe { ffi::gset_effect_u64(event, raw) })
  }

  fn interpret(state: GSet) -> GSetInterp<u64> {
    lean_inc_ref(state.0);
    GSetInterp(state.0, PhantomData)
  }
}

impl GSet for LeanGSet {}

impl LeanGSet {
  pub fn empty() -> GSet {
    unsafe {
      lean_inc_ref(ffi::gset_empty_u64);
      GSet(ffi::gset_empty_u64)
    }
  }
}
