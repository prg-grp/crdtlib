use crate::combinator::derived::map_op::map_op;
use crate::combinator::principal::product::{Product, product};
use crate::combinator::principal::traverse::Traverse;
use crdtlib_api::Datatype;

pub fn joint_product<C1, C2>(
  c1: C1,
  c2: C2,
) -> Product<
  Traverse<C1, (C1::Op, C2::Op), impl Fn(&(C1::Op, C2::Op)) -> Vec<C1::Op>>,
  Traverse<C2, (C1::Op, C2::Op), impl Fn(&(C1::Op, C2::Op)) -> Vec<C2::Op>>,
>
where
  C1: Datatype<Op: Clone>,
  C2: Datatype<Op: Clone>,
{
  product(
    map_op(|o: &(C1::Op, C2::Op)| o.0.clone(), c1),
    map_op(|o: &(C1::Op, C2::Op)| o.1.clone(), c2),
  )
}
