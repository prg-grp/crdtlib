use crate::crdt::basic::Crdt;

pub trait Counter64: Crdt<Op = i64, State = i64, Interp = i64> {}
pub trait Counter32: Crdt<Op = i32, State = i32, Interp = i32> {}

mod ffi {
  unsafe extern "C" {
    pub fn counter64_effect(event: i64, state: i64) -> i64;
    pub fn counter64_interpret(state: i64) -> i64;
    pub fn counter32_effect(event: i32, state: i32) -> i32;
    pub fn counter32_interpret(state: i32) -> i32;
  }
}

pub struct LeanCounter64;

impl Crdt for LeanCounter64 {
  type Op = i64;
  type State = i64;
  type Interp = i64;

  fn effect(event: i64, state: i64) -> i64 {
    unsafe { ffi::counter64_effect(event, state) }
  }
  fn interpret(state: i64) -> i64 {
    unsafe { ffi::counter64_interpret(state) }
  }
}

impl Counter64 for LeanCounter64 {}

pub struct LeanCounter32;

impl Crdt for LeanCounter32 {
  type Op = i32;
  type State = i32;
  type Interp = i32;

  fn effect(event: i32, state: i32) -> i32 {
    unsafe { ffi::counter32_effect(event, state) }
  }
  fn interpret(state: i32) -> i32 {
    unsafe { ffi::counter32_interpret(state) }
  }
}

impl Counter32 for LeanCounter32 {}
