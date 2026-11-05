use crate::combinator::principal::traverse::{Traverse, traverse};
use crdtlib_api::Datatype;

pub fn map_op<O, C: Datatype, F: Fn(&O) -> C::Op>(
  f: F,
  c: C,
) -> Traverse<C, O, impl Fn(&O) -> Vec<C::Op>> {
  traverse(move |o: &O| vec![f(o)], c)
}
