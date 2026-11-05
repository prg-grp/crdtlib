use crdtlib_api::{Crdt, Datatype};
use crdtlib_bindings::crdt::std::scalar::counter::{LeanCounter32, LeanCounter64};
use crdtlib_bindings::crdt::std::set::gset::{GSetState, LeanGSet};

fn main() {
  crdtlib_bindings::init();

  let c = LeanCounter64;
  let s = [5, -2, 10].iter().fold(0, |s, op| c.effect(op, s));
  println!("Counter64: 5 + (-2) + 10 = {}", c.interpret(&s));

  let c = LeanCounter32;
  let s = [3, 7].iter().fold(0, |s, op| c.effect(op, s));
  println!("Counter32: 3 + 7 = {}", c.interpret(&s));

  let g = LeanGSet;
  let s = [42, 17]
    .iter()
    .fold(GSetState::default(), |s, op| g.effect(op, s));
  let i = g.interpret(&s);
  println!("GSet contains:");
  for k in [42, 17, 0, 99] {
    println!("  {k:>2}: {}", i.mem(k));
  }
}
