use crate::combinator::principal::product::{Product, product};
use crate::combinator::principal::traverse::{Traverse, traverse};
use crdtlib_api::{Datatype, Sum};

pub fn disjoint_product<C1, C2>(
  c1: C1,
  c2: C2,
) -> Product<
  Traverse<C1, Sum<C1::Op, C2::Op>, impl Fn(&Sum<C1::Op, C2::Op>) -> Vec<C1::Op>>,
  Traverse<C2, Sum<C1::Op, C2::Op>, impl Fn(&Sum<C1::Op, C2::Op>) -> Vec<C2::Op>>,
>
where
  C1: Datatype<Op: Clone>,
  C2: Datatype<Op: Clone>,
{
  product(
    traverse(
      |o: &Sum<C1::Op, C2::Op>| o.get_left().cloned().into_iter().collect(),
      c1,
    ),
    traverse(
      |o: &Sum<C1::Op, C2::Op>| o.get_right().cloned().into_iter().collect(),
      c2,
    ),
  )
}
