use std::ffi::c_void;
pub type LeanObj = *mut c_void;

unsafe extern "C" {
  fn lean_initialize();
  fn lean_io_mark_end_initialization();
  fn lean_io_result_show_error(r: LeanObj);
  fn lean_dec_ref_cold(o: LeanObj);

  fn initialize_crdtlib_Crdtlib_CRDT_Std_Scalar_Counter(builtin: u8) -> LeanObj;
  fn initialize_crdtlib_Crdtlib_CRDT_Std_Set_GHashSet(builtin: u8) -> LeanObj;
}

#[inline(always)]
fn lean_box(n: usize) -> LeanObj {
  ((n << 1) | 1) as LeanObj
}

#[inline(always)]
fn lean_is_scalar(o: LeanObj) -> bool {
  (o as usize) & 1 == 1
}

// lean_object layout on arm64 LE: [0..3] m_rc (i32), [4..5] m_cs_sz, [6] m_other, [7] m_tag
#[inline(always)]
unsafe fn lean_ptr_tag(o: LeanObj) -> u8 {
  unsafe { *((o as *const u8).add(7)) }
}

#[inline(always)]
unsafe fn lean_io_result_is_ok(res: LeanObj) -> bool {
  unsafe { lean_ptr_tag(res) == 0 }
}

#[inline(always)]
pub fn lean_inc_ref(o: LeanObj) {
  if lean_is_scalar(o) {
    return;
  }
  unsafe {
    let rc_ptr = o as *mut i32;
    let rc = *rc_ptr;
    if rc != 0 {
      *rc_ptr = rc + 1;
    }
  }
}

#[inline(always)]
pub fn lean_dec_ref(o: LeanObj) {
  if lean_is_scalar(o) {
    return;
  }
  let rc_ptr = o as *mut i32;
  unsafe {
    let rc = *rc_ptr;
    if rc > 1 {
      *rc_ptr = rc - 1;
    } else if rc != 0 {
      lean_dec_ref_cold(o);
    }
  }
}

fn run_initializer(f: unsafe extern "C" fn(u8) -> LeanObj) {
  unsafe {
    let res = f(1);
    if lean_io_result_is_ok(res) {
      lean_dec_ref(res);
    } else {
      lean_io_result_show_error(res);
      lean_dec_ref(res);
      panic!("Lean module initialization failed");
    }
  }
}

pub fn init() {
  unsafe {
    lean_initialize();
    run_initializer(initialize_crdtlib_Crdtlib_CRDT_Std_Scalar_Counter);
    run_initializer(initialize_crdtlib_Crdtlib_CRDT_Std_Set_GHashSet);
    lean_io_mark_end_initialization();
  }
}
