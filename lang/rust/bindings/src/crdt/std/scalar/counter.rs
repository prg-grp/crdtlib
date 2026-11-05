use crdtlib_api::{Crdt, Datatype};

mod ffi {
  unsafe extern "C" {
    pub fn counter64_effect(event: i64, state: i64) -> i64;
    pub fn counter64_interpret(state: i64) -> i64;
    pub fn counter32_effect(event: i32, state: i32) -> i32;
    pub fn counter32_interpret(state: i32) -> i32;
  }
}

/// `counter64`: `ac_fun Int64 (· + ·)`.
#[derive(Clone, Copy, Debug, Default)]
pub struct LeanCounter64;

impl Datatype for LeanCounter64 {
  type Op = i64;
  type State = i64;
  type Interp = i64;

  fn interpret(&self, state: &i64) -> i64 {
    unsafe { ffi::counter64_interpret(*state) }
  }
}

impl Crdt for LeanCounter64 {
  fn effect(&self, op: &i64, state: i64) -> i64 {
    unsafe { ffi::counter64_effect(*op, state) }
  }
}

#[derive(Clone, Copy, Debug, Default)]
pub struct LeanCounter32;

impl Datatype for LeanCounter32 {
  type Op = i32;
  type State = i32;
  type Interp = i32;

  fn interpret(&self, state: &i32) -> i32 {
    unsafe { ffi::counter32_interpret(*state) }
  }
}

impl Crdt for LeanCounter32 {
  fn effect(&self, op: &i32, state: i32) -> i32 {
    unsafe { ffi::counter32_effect(*op, state) }
  }
}
