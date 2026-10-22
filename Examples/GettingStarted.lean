import Crdtlib

/-!
Examples shown on the "Get started" page of the website.
The site embeds the regions between `ANCHOR` comments, so they must keep compiling.
-/

namespace GettingStarted

-- ANCHOR: compose
/-- Operations on a task: tag it, or adjust its priority. -/
inductive TaskOp
  | tag (label : String)
  | bump (priority : Int)

/-- A replicated task: a grow-only set of tags next to a priority counter. -/
def task : CRDT TaskOp (GSet String × Int) (SetInterp String × Int) :=
  map_op (λ | .tag l => .inl l | .bump n => .inr n)
    (disjoint_product (gset String) counter)
-- ANCHOR_END: compose

-- ANCHOR: run
/-- Two replicas receive the same operations in different orders… -/
def replicaA := task.effect (.bump 2) (task.effect (.tag "urgent") 0)
def replicaB := task.effect (.tag "urgent") (task.effect (.bump 2) 0)

-- …and observe the same task.
#guard (task.interpret replicaA).1.mem "urgent" && (task.interpret replicaB).1.mem "urgent"
#guard (task.interpret replicaA).2 == (task.interpret replicaB).2
-- ANCHOR_END: run

-- ANCHOR: free
/-- No new proof needed: commutativity comes with the composite. -/
example (a b : TaskOp) : task.effect b ∘ task.effect a = task.effect a ∘ task.effect b :=
  task.commutative a b
-- ANCHOR_END: free

-- ANCHOR: primitive
/-- A primitive CRDT written by hand: replicas keep the largest value seen. -/
def high_score : CRDT Nat Nat Nat where
  effect := max
  interpret := id
  commutative a b := by
    funext s
    exact max_left_comm b a s
-- ANCHOR_END: primitive

end GettingStarted
