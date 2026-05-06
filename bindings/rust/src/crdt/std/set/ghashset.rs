use crate::crdt::basic::Crdt;
use crate::lean_rt::{LeanObj, lean_dec_ref, lean_inc_ref};
use std::marker::PhantomData;

mod ffi {
  use crate::lean_rt::LeanObj;
  unsafe extern "C" {
    pub static ghashset_empty_u64: LeanObj;
    pub fn ghashset_effect_u64(event: u64, state: LeanObj) -> LeanObj;
    pub fn ghashset_interpret_mem_u64(key: u64, state: LeanObj) -> u8;
  }
}

pub struct GHashSetState(LeanObj);

impl Clone for GHashSetState {
  fn clone(&self) -> Self {
    lean_inc_ref(self.0);
    GHashSetState(self.0)
  }
}

impl Drop for GHashSetState {
  fn drop(&mut self) {
    lean_dec_ref(self.0);
  }
}

unsafe impl Send for GHashSetState {}
unsafe impl Sync for GHashSetState {}

pub struct GHashSetInterpretation<T>(LeanObj, PhantomData<T>);

impl GHashSetInterpretation<u64> {
  pub fn mem(&self, key: u64) -> bool {
    unsafe {
      lean_inc_ref(self.0);
      ffi::ghashset_interpret_mem_u64(key, self.0) != 0
    }
  }
}

pub trait GHashSet:
  Crdt<Op = u64, State = GHashSetState, Interp = GHashSetInterpretation<u64>>
{
}

pub struct LeanGHashSet;

impl Crdt for LeanGHashSet {
  type Op = u64;
  type State = GHashSetState;
  type Interp = GHashSetInterpretation<u64>;

  fn effect(event: u64, state: GHashSetState) -> GHashSetState {
    let raw = state.0;
    std::mem::forget(state);
    GHashSetState(unsafe { ffi::ghashset_effect_u64(event, raw) })
  }

  fn interpret(state: GHashSetState) -> GHashSetInterpretation<u64> {
    lean_inc_ref(state.0);
    GHashSetInterpretation(state.0, PhantomData)
  }
}

impl GHashSet for LeanGHashSet {}

impl LeanGHashSet {
  pub fn empty() -> GHashSetState {
    unsafe {
      lean_inc_ref(ffi::ghashset_empty_u64);
      GHashSetState(ffi::ghashset_empty_u64)
    }
  }
}
