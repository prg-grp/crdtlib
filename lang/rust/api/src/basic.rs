#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub struct Event<T, O> {
  pub t: T,
  pub o: O,
}

pub fn concurrent<T: PartialOrd>(t1: &T, t2: &T) -> bool {
  t1.partial_cmp(t2).is_none()
}

pub trait Datatype {
  type Op;
  type State;
  type Interp;

  fn interpret(&self, state: &Self::State) -> Self::Interp;
}

pub trait Crdt: Datatype {
  fn effect(&self, op: &Self::Op, state: Self::State) -> Self::State;

  fn commutes(&self, e1: &Self::Op, e2: &Self::Op, state: &Self::State) -> bool
  where
    Self::State: Clone + PartialEq,
  {
    self.effect(e2, self.effect(e1, state.clone()))
      == self.effect(e1, self.effect(e2, state.clone()))
  }

  fn timed(self) -> Timed<Self>
  where
    Self: Sized,
  {
    Timed(self)
  }
}

pub trait CrdtT<T: PartialOrd>: Datatype {
  fn effect_t(&self, t: &T, op: &Self::Op, state: Self::State) -> Self::State;

  fn commutes_t(&self, t1: &T, o1: &Self::Op, t2: &T, o2: &Self::Op, state: &Self::State) -> bool
  where
    Self::State: Clone + PartialEq,
  {
    !concurrent(t1, t2)
      || self.effect_t(t2, o2, self.effect_t(t1, o1, state.clone()))
        == self.effect_t(t1, o1, self.effect_t(t2, o2, state.clone()))
  }
}

#[derive(Clone, Copy, Debug)]
pub struct Timed<C>(pub C);

impl<C: Datatype> Datatype for Timed<C> {
  type Op = C::Op;
  type State = C::State;
  type Interp = C::Interp;

  fn interpret(&self, state: &C::State) -> C::Interp {
    self.0.interpret(state)
  }
}

impl<T: PartialOrd, C: Crdt> CrdtT<T> for Timed<C> {
  fn effect_t(&self, _t: &T, op: &C::Op, state: C::State) -> C::State {
    self.0.effect(op, state)
  }
}
