import Shared

/-!
# The showcase

The slides of the landing page's carousel. Each slide is a CRDT drawn as its construction: a tree
whose inner nodes are combinators and whose leaves are the CRDTs they combine. A few operations are
then played on it: each one enters at the root, is translated by every combinator on its way down,
and updates one or more leaves; the application then reads the new interpreted state at the root.

This is illustration, not a checked excerpt. The constructions follow the library and the paper,
but the operations, the translated operations on the edges, and the states are written by hand.
-/

namespace Home

open Shared

/--
A node of a construction. Leaves are CRDTs, inner nodes are combinators. A leaf with role `param`
is a CRDT that is itself built from combinators, shown as one box to keep the drawing small.
-/
inductive Node where
  | mk (key : String) (code : String) (note : String) (role : Role) (state : String)
      (children : Array Node)

instance : Inhabited Node := ⟨.mk "" "" "" .primitive "" #[]⟩

namespace Node

def key : Node → String | .mk k .. => k
def code : Node → String | .mk _ c .. => c
def note : Node → String | .mk _ _ n .. => n
def role : Node → Role | .mk _ _ _ r .. => r
/-- The state a leaf starts in. -/
def state : Node → String | .mk _ _ _ _ s _ => s
def children : Node → Array Node | .mk _ _ _ _ _ cs => cs

/-- `associate` keeps one copy of its argument per key; the drawing stacks that copy. -/
def keyed (n : Node) : Bool := n.code.startsWith "associate"

end Node

def principal (code note : String) (children : Array Node) : Node :=
  .mk code code note .principal "" children

def derived (code note : String) (children : Array Node) : Node :=
  .mk code code note .derived "" children

/-- A primitive CRDT. `key` names it in the steps. -/
def primitive (key code note state : String) : Node :=
  .mk key code note .primitive state #[]

/-- A CRDT that is itself built from combinators, drawn as a single box. -/
def composite (key code note state : String) : Node :=
  .mk key code note .param state #[]

/--
One delivery of an operation to a leaf. `labels` has one entry for each edge below the root on the
way to the leaf: the operation as it arrives at the next node. The leaf's state becomes `state`.
-/
structure Hop where
  target : String
  labels : List String
  state : String

/--
An operation issued by the application, and what the application reads afterwards.

After the operation has been applied, the state is interpreted bottom-up, and the drawing shows
what each node reads as. Most of that follows from the construction: a leaf reads as its state, a
product pairs what its parts read as, and `map_op`, `traverse` and `associate` change nothing. The
root reads as `view`. `reads` gives the rest, by node key: what a combinator whose interpretation
does something, such as `map_interpretation` or `tagged_union`, reads as below the root.
-/
structure Step where
  op : String
  hops : Array Hop
  view : String
  reads : List (String × String) := []

structure Slide where
  /-- The tab label. -/
  tab : String
  kicker : String
  title : String
  blurb : String
  /-- The construction as a Lean expression, abbreviated. -/
  expr : String
  tree : Node
  /-- What the application reads before any step. -/
  view : String
  steps : Array Step
  /-- Where to read more, shown as "{name} Reference": the name and the URL. -/
  reference : String × String

/-- A catalog entry, by its name in the catalog; `label` names it in the link, if different. -/
private def catalogEntry (name : String) (label : String := name) : String × String :=
  match findCrdt? name with
  | some c => (label, docsUrl "catalog" c.slug)
  | none => (label, docsUrl "catalog")

/-- The paper, for the case studies. -/
private def paperEntry : String × String := ("Paper", s!"https://doi.org/{paper.doi}")

def slides : Array Slide := #[
  { tab := "Task"
    kicker := "Two CRDTs side by side"
    title := "A task with tags and a priority"
    blurb := "A grow-only set of tags next to a counter. `disjoint_product` keeps both: an operation `.inl` goes to the set, and `.inr` to the counter."
    expr := "disjoint_product (gset String) counter"
    tree :=
      derived "disjoint_product" "two CRDTs, side by side" #[
        primitive "tags" "gset String" "tags" "{}",
        primitive "prio" "counter" "priority" "0"]
    view := "({}, 0)"
    steps := #[
      { op := ".inl \"urgent\"", view := "({urgent}, 0)",
        hops := #[{ target := "tags", labels := ["\"urgent\""], state := "{urgent}" }] },
      { op := ".inr 2", view := "({urgent}, 2)",
        hops := #[{ target := "prio", labels := ["+2"], state := "2" }] },
      { op := ".inl \"ux\"", view := "({urgent, ux}, 2)",
        hops := #[{ target := "tags", labels := ["\"ux\""], state := "{urgent, ux}" }] }]
    reference := ("DisjointProduct", docsUrl "combinators" "disjointproduct") },

  { tab := "LWW Register"
    kicker := "Conflict resolution on read"
    title := "A last-writer-wins register"
    blurb := "A multi-value register keeps all concurrent writes.
    On read, `map_interpretation` uses a user-defined total order to determine the latest among those values and returns it."
    expr := "map_interpretation largest (mv_regₜ String)"
    tree :=
      principal "map_interpretation" "reads the largest" #[
        primitive "reg" "mv_regₜ String" "concurrent writes" "{}"]
    view := "\"\""
    steps := #[
      { op := "write \"blue\"", view := "\"blue\"",
        hops := #[{ target := "reg", labels := ["\"blue\" @ A"], state := "{blue}" }] },
      { op := "write \"red\" ∥", view := "\"red\"",
        hops := #[{ target := "reg", labels := ["\"red\" @ B, concurrent"], state := "{blue, red}" }] },
      { op := "write \"green\"", view := "\"green\"",
        hops := #[{ target := "reg", labels := ["\"green\" @ A, after both"], state := "{green}" }] }]
    reference := catalogEntry "MV-LWW Register" "LWW Register" },

  { tab := "Shopping list"
    kicker := "A keyed family of CRDTs"
    title := "A counter for every element"
    blurb := "The PN-Set: `associate` turns one counter into a counter per element. Adds count up, removes count down. The set keeps only the elements with a positive counter on interpretation."
    expr := "map_interpretation positive (map_op ±1 (associate σ counter))"
    tree :=
      principal "map_interpretation" "keeps counts above 0" #[
        derived "map_op" "add ↦ +1, remove ↦ −1" #[
          principal "associate σ" "a copy per element" #[
            primitive "count" "counter" "count" "{}"]]]
    view := "{}"
    steps := #[
      { op := "add \"milk\"", view := "{milk}",
        hops := #[{ target := "count", labels := ["add \"milk\"", "(\"milk\", +1)", "+1 at milk"], state := "{milk ↦ 1}" }] },
      { op := "add \"eggs\"", view := "{milk, eggs}",
        hops := #[{ target := "count", labels := ["add \"eggs\"", "(\"eggs\", +1)", "+1 at eggs"], state := "{milk ↦ 1, eggs ↦ 1}" }] },
      { op := "remove \"milk\"", view := "{eggs}",
        hops := #[{ target := "count", labels := ["remove \"milk\"", "(\"milk\", −1)", "−1 at milk"], state := "{milk ↦ 0, eggs ↦ 1}" }] }]
    reference := catalogEntry "PN-Set" },

  { tab := "OR-Set"
    kicker := "Observed-remove semantics"
    title := "Concurrent adds survive removes"
    blurb := "Adds carry a unique token, and a remove cancels only the tagged adds it has seen using their unique tokens. On interpretation, the set contains elements who's unique token was not removed."
    expr := "map_interpretation (adds \\ removes) (map_op route (disjoint_product union_set union_set))"
    tree :=
      principal "map_interpretation" "adds minus removes" #[
        derived "map_op" "add → left, remove → right" #[
          derived "disjoint_product" "two CRDTs, side by side" #[
            primitive "adds" "union_set (σ × tok)" "adds" "{}",
            primitive "removes" "union_set (σ × tok)" "removes" "{}"]]]
    view := "{}"
    steps := #[
      { op := "add milk #1", view := "{milk}",
        hops := #[{ target := "adds", labels := ["add milk #1", ".inl {(milk, 1)}", "{(milk, 1)}"], state := "{(milk, 1)}" }] },
      { op := "remove {(milk, 1)}", view := "{}",
        hops := #[{ target := "removes", labels := ["remove {(milk, 1)}", ".inr {(milk, 1)}", "{(milk, 1)}"], state := "{(milk, 1)}" }] },
      { op := "add milk #2", view := "{milk}",
        hops := #[{ target := "adds", labels := ["add milk #2", ".inl {(milk, 2)}", "{(milk, 2)}"], state := "{(milk, 1), (milk, 2)}" }] }]
    reference := catalogEntry "OR-Set" },

  { tab := "List"
    kicker := ""
    title := "A partially ordered list"
    blurb := "An insert adds a node and, through `traverse`, two edges to a graph.
    Removals are tracked in a tombstone set.
    Reading the list traverses the graph in order."
    expr := "map_interpretation po_traversal (disjoint_product (map_op _ (joint_product (gset σ) (po_edges σ))) (map_op _ (gset σ)))"
    tree :=
      principal "map_interpretation" "traverses the graph in order" #[
        derived "disjoint_product" "insert → left, remove → right" #[
          derived "map_op" "keeps the element" #[
            derived "joint_product" "updates both, at once" #[
              primitive "nodes" "gset σ" "nodes" "{}",
              principal "traverse" "one insert, two edges" #[
                principal "associate σ" "successors per node" #[
                  primitive "succ" "gset σ" "edges" "{}"]]]],
          derived "map_op" "unwraps the element" #[
            primitive "tomb" "gset σ" "tombstones" "{}"]]]
    view := "\"\""
    steps := #[
      { op := "insert ⊥ H ⊤", view := "\"H\"",
        hops := #[
          { target := "nodes", labels := ["insert ⊥ H ⊤", "⟨⊥, H, ⊤⟩", "(H, ⟨⊥, H, ⊤⟩)", "H"], state := "{H}" },
          { target := "succ", labels := ["insert ⊥ H ⊤", "⟨⊥, H, ⊤⟩", "(H, ⟨⊥, H, ⊤⟩)", "⟨⊥, H, ⊤⟩", "(⊥, H)", "H"], state := "{⊥→H}" },
          { target := "succ", labels := ["insert ⊥ H ⊤", "⟨⊥, H, ⊤⟩", "(H, ⟨⊥, H, ⊤⟩)", "⟨⊥, H, ⊤⟩", "(H, ⊤)", "⊤"], state := "{⊥→H, H→⊤}" }] },
      { op := "insert H i ⊤", view := "\"Hi\"",
        hops := #[
          { target := "nodes", labels := ["insert H i ⊤", "⟨H, i, ⊤⟩", "(i, ⟨H, i, ⊤⟩)", "i"], state := "{H, i}" },
          { target := "succ", labels := ["insert H i ⊤", "⟨H, i, ⊤⟩", "(i, ⟨H, i, ⊤⟩)", "⟨H, i, ⊤⟩", "(H, i)", "i"], state := "{⊥→H, H→⊤, H→i}" },
          { target := "succ", labels := ["insert H i ⊤", "⟨H, i, ⊤⟩", "(i, ⟨H, i, ⊤⟩)", "⟨H, i, ⊤⟩", "(i, ⊤)", "⊤"], state := "{⊥→H, H→⊤, H→i, i→⊤}" }] },
      { op := "remove H", view := "\"i\"",
        hops := #[{ target := "tomb", labels := ["remove H", "⟨H⟩", "H"], state := "{H}" }] }]
    reference := catalogEntry "List" },

  { tab := "Tic-tac-toe"
    kicker := ""
    title := "A tree of Tic-tac-toe games"
    blurb := "Games fork into a tree, keyed by path, and every node has a board and a threaded chat. `traverse` turns one chat message into two list operations: create a message node, then write the text."
    expr := "traverse route (associate (List String) (disjoint_product (mv_lwwₜ Board) (polist_with_valuesₜ Cursor (mv_lwwₜ String))))"
    tree :=
      principal "traverse" "one operation, several updates" #[
        principal "associate (List String)" "a game per path" #[
          derived "disjoint_product" "board and chat" #[
            composite "board" "mv_lwwₜ Board" "the board" "{}",
            composite "chat" "polist_with_valuesₜ" "the chat" "{}"]]]
    view := "{}"
    steps := #[
      { op := "place [] ⊞", view := "{[] ↦ (⊞, [])}",
        reads := [("associate (List String)", "{[] ↦ (⊞, [])}")],
        hops := #[{ target := "board", labels := ["⟨[], .inl ⊞⟩", ".inl ⊞ at []", "⊞"], state := "{[] ↦ ⊞}" }] },
      { op := "chat [] \"gg\"", view := "{[] ↦ (⊞, [gg])}",
        reads := [("associate (List String)", "{[] ↦ (⊞, [gg])}")],
        hops := #[
          { target := "chat", labels := ["⟨[], .inr (insert m₁)⟩", ".inr (insert m₁) at []", "insert m₁"], state := "{[] ↦ [_]}" },
          { target := "chat", labels := ["⟨[], .inr (mutate m₁ \"gg\")⟩", ".inr (mutate m₁) at []", "write \"gg\" at m₁"], state := "{[] ↦ [gg]}" }] },
      { op := "fork [b] ⊞′", view := "{[] ↦ (⊞, [gg]), [b] ↦ (⊞′, [])}",
        reads := [("associate (List String)", "{[] ↦ (⊞, [gg]), [b] ↦ (⊞′, [])}")],
        hops := #[{ target := "board", labels := ["⟨[b], .inl ⊞′⟩", ".inl ⊞′ at [b]", "⊞′"], state := "{[] ↦ ⊞, [b] ↦ ⊞′}" }] }]
    reference := paperEntry },

  { tab := "JSON"
    kicker := ""
    title := "A JSON document, like Automerge"
    blurb := "Objects are keyed by id, and each one is a map or a list, chosen by a tagged union. One edit fans out to several objects, and the document is read off the objects from `root`. It runs 2.4 to 6 times faster than Automerge 0.7 to 0.9."
    expr := "traverse route (associate Oid (tagged_unionₜ (mapₜ Oid Key) (listₜ Oid Cursor)))"
    tree :=
      principal "traverse" "one edit, several updates" #[
        principal "associate Oid" "an object per id" #[
          derived "tagged_unionₜ" "a map or a list" #[
            composite "map" "mapₜ Oid Key" "maps" "{}",
            composite "list" "listₜ Oid Cursor" "lists" "{}",
            composite "choice" "mv_lwwₜ Choice" "map or list?" "{}"]]]
    view := "{}"
    steps := #[
      { op := "put_list root \"todos\" o₁", view := "{root ↦ {todos: o₁}, o₁ ↦ []}",
        reads := [("tagged_unionₜ", "{root ↦ {todos: o₁}, o₁ ↦ []}")],
        hops := #[
          { target := "map", labels := ["⟨root, put \"todos\"⟩", "map: put \"todos\"", "put \"todos\""], state := "{root ↦ {todos}}" },
          { target := "map", labels := ["⟨root, update \"todos\" o₁⟩", "map: update \"todos\"", "todos ↦ o₁"], state := "{root ↦ {todos: o₁}}" },
          { target := "choice", labels := ["⟨o₁, right⟩", "choose: list", "list"], state := "{o₁ ↦ list}" }] },
      { op := "insert o₁ ⊥ \"milk\"", view := "{root ↦ {todos: o₁}, o₁ ↦ [milk]}",
        reads := [("tagged_unionₜ", "{root ↦ {todos: o₁}, o₁ ↦ [milk]}")],
        hops := #[
          { target := "list", labels := ["⟨o₁, insert p₁⟩", "list: insert p₁", "insert p₁"], state := "{o₁ ↦ [_]}" },
          { target := "list", labels := ["⟨o₁, mutate p₁ \"milk\"⟩", "list: mutate p₁", "p₁ ↦ \"milk\""], state := "{o₁ ↦ [milk]}" }] },
      { op := "insert o₁ p₁ \"eggs\"", view := "{root ↦ {todos: o₁}, o₁ ↦ [milk, eggs]}",
        reads := [("tagged_unionₜ", "{root ↦ {todos: o₁}, o₁ ↦ [milk, eggs]}")],
        hops := #[
          { target := "list", labels := ["⟨o₁, insert p₂⟩", "list: insert p₂", "insert p₂"], state := "{o₁ ↦ [milk, _]}" },
          { target := "list", labels := ["⟨o₁, mutate p₂ \"eggs\"⟩", "list: mutate p₂", "p₂ ↦ \"eggs\""], state := "{o₁ ↦ [milk, eggs]}" }] }]
    reference := paperEntry }
]

end Home
