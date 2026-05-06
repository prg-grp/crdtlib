pub trait Crdt {
  type Op: Clone;
  type State: Clone;
  type Interp;

  fn effect(event: Self::Op, state: Self::State) -> Self::State;
  fn interpret(state: Self::State) -> Self::Interp;
}
