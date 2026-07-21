mod crdt;
mod lean_rt;

use crdt::basic::Crdt;
use crdt::std::scalar::counter::{LeanCounter32, LeanCounter64};
use crdt::std::set::gset::LeanGSet;

fn main() {
  lean_rt::init();

  let s0: i64 = 0;
  let s1 = LeanCounter64::effect(5, s0);
  let s2 = LeanCounter64::effect(-2, s1);
  let s3 = LeanCounter64::effect(10, s2);
  println!(
    "Counter64: 5 + (-2) + 10 = {}",
    LeanCounter64::interpret(s3)
  );

  let s0: i32 = 0;
  let s1 = LeanCounter32::effect(3, s0);
  let s2 = LeanCounter32::effect(7, s1);
  println!("Counter32: 3 + 7 = {}", LeanCounter32::interpret(s2));

  let s0 = LeanGSet::empty();
  let s1 = LeanGSet::effect(42, s0);
  let s2 = LeanGSet::effect(17, s1);
  let g = LeanGSet::interpret(s2);

  println!("GSet contains:");
  println!("  42: {}", g.mem(42));
  println!("  17: {}", g.mem(17));
  println!("   0: {}", g.mem(0));
  println!("  99: {}", g.mem(99));
}
