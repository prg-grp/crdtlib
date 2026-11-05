#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Sum<A, B> {
  Inl(A),
  Inr(B),
}

impl<A, B> Sum<A, B> {
  pub fn get_left(&self) -> Option<&A> {
    match self {
      Sum::Inl(a) => Some(a),
      Sum::Inr(_) => None,
    }
  }

  pub fn get_right(&self) -> Option<&B> {
    match self {
      Sum::Inl(_) => None,
      Sum::Inr(b) => Some(b),
    }
  }
}
