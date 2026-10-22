module

public import Shared.Basic

@[expose] public section

/-!
# Site data

Facts about the library and the paper that the site renders in several places: the combinators,
the CRDTs in the catalog, how each CRDT is assembled ("recipes"), and the paper's table of which
combinators each construction uses. Keep these in sync with the library (`Crdtlib`) and the paper; the code
excerpts on the pages are checked against the library, but this metadata is not.
-/

namespace Shared

/-- What role a building block plays. Each role has its own color on the site. -/
inductive Role where
  /-- One of the five principal combinators. -/
  | principal
  /-- A combinator defined in terms of the principal ones. -/
  | derived
  /-- A CRDT written directly, with a hand-written commutativity proof. -/
  | primitive
  /-- A parameter: whatever CRDT the user plugs in. -/
  | param
deriving Repr, BEq

def Role.cls : Role → String
  | .principal => "principal"
  | .derived => "derived"
  | .primitive => "primitive"
  | .param => "param"

/--
How a CRDT is assembled: combinators applied to smaller CRDTs. Rendered as nested boxes.
-/
inductive Recipe where
  | leaf (code : String) (role : Role := .primitive)
  | node (code : String) (role : Role) (args : Array Recipe)
deriving Repr

namespace Recipe

def principal (code : String) (args : Array Recipe) : Recipe := .node code .principal args
def derived (code : String) (args : Array Recipe) : Recipe := .node code .derived args

end Recipe

open Recipe

/-- The three type parameters of a CRDT: operations, state, and interpretation. -/
structure Slots where
  ω : String
  σ : String
  γ : String

/-- A combinator, as described on the site. -/
structure CombinatorInfo where
  /-- The name used in the paper, e.g. `MapState`. -/
  name : String
  /-- How it is applied in Lean, e.g. `map_state f f'`. -/
  usage : String
  role : Role
  blurb : String
  /-- The type parameters of the result. -/
  result : Slots
  /-- Which of `ω`, `σ`, `γ` the combinator changes. -/
  changes : List String

def CombinatorInfo.slug (c : CombinatorInfo) : String := Components.createSlug c.name

/-- The combinators, principal ones first, in the order of the paper. -/
def combinators : Array CombinatorInfo := #[
  { name := "Product", usage := "product c₁ c₂", role := .principal,
    blurb := "Applies every operation to two CRDTs at once. The only combinator that combines two states.",
    result := ⟨"ω", "σ₁ × σ₂", "γ₁ × γ₂"⟩, changes := ["σ", "γ"] },
  { name := "MapState", usage := "map_state f f'", role := .principal,
    blurb := "Changes how the state is laid out, through a function with a left inverse.",
    result := ⟨"ω", "σ₂", "γ"⟩, changes := ["σ"] },
  { name := "Associate", usage := "associate κ c", role := .principal,
    blurb := "Turns one CRDT into a keyed family: a map from keys to independent copies.",
    result := ⟨"κ × ω", "Associate κ σ", "AssociateInterp κ γ"⟩, changes := ["ω", "σ", "γ"] },
  { name := "Traverse", usage := "traverse f c", role := .principal,
    blurb := "Turns one operation into a list of inner operations: none, one, or several.",
    result := ⟨"ω₂", "σ", "γ"⟩, changes := ["ω"] },
  { name := "MapInterpretation", usage := "map_interpretation f c", role := .principal,
    blurb := "Changes what the application observes. Operations and state stay the same.",
    result := ⟨"ω", "σ", "γ₂"⟩, changes := ["γ"] },
  { name := "MapOp", usage := "map_op f c", role := .derived,
    blurb := "Translates each operation into exactly one inner operation. A traverse with singleton lists.",
    result := ⟨"ω₂", "σ", "γ"⟩, changes := ["ω"] },
  { name := "DisjointProduct", usage := "disjoint_product c₁ c₂", role := .derived,
    blurb := "Two CRDTs side by side; each operation targets one of them.",
    result := ⟨"ω₁ ⊕ ω₂", "σ₁ × σ₂", "γ₁ × γ₂"⟩, changes := ["ω", "σ", "γ"] },
  { name := "JointProduct", usage := "joint_product c₁ c₂", role := .derived,
    blurb := "Two CRDTs side by side; each operation updates both, atomically.",
    result := ⟨"ω₁ × ω₂", "σ₁ × σ₂", "γ₁ × γ₂"⟩, changes := ["ω", "σ", "γ"] },
  { name := "TaggedUnion", usage := "tagged_unionₜ c₁ c₂", role := .derived,
    blurb := "Either one CRDT or the other, with a register deciding which one is active.",
    result := ⟨"(ω₁ ⊕ ω₂) ⊕ Choice", "(σ₁ × σ₂) × …", "γ₁ ⊕ γ₂"⟩, changes := ["ω", "σ", "γ"] }
]

/-- A CRDT from the catalog. -/
structure CrdtInfo where
  /-- Display name, also the heading on the catalog page. -/
  name : String
  /-- The Lean definition. -/
  code : String
  blurb : String
  slots : Slots
  recipe : Recipe
  /-- Shown on the home page. -/
  featured : Bool := false

def CrdtInfo.slug (c : CrdtInfo) : String := Components.createSlug c.name

def gsetR : Recipe :=
  derived "map_op" #[principal "associate σ" #[leaf "gcounter"]]

def poEdgesR : Recipe :=
  principal "traverse" #[principal "associate σ" #[leaf "gset σ"]]

def crdts : Array CrdtInfo := #[
  { name := "LWW Register", code := "lww σ",
    blurb := "The write with the greatest Lamport timestamp wins; ties are broken by value.",
    slots := ⟨"Lamport σ", "Lamport σ", "Lamport σ"⟩,
    recipe := leaf "join (Lamport σ)" },
  { name := "MV Register", code := "mv_regₜ σ",
    blurb := "Keeps every write that no later write has overwritten.",
    slots := ⟨"σ", "Finset (Event τ σ)", "Finset (Event τ σ)"⟩,
    recipe := leaf "mv_regₜ σ" },
  { name := "MV-LWW Register", code := "mv_lwwₜ σ",
    blurb := "A multi-value register read as one value: the largest of the concurrent writes.",
    slots := ⟨"σ", "Finset (Event τ σ)", "σ"⟩,
    recipe := principal "map_interpretation" #[leaf "mv_regₜ σ"] },
  { name := "G-Set", code := "gset σ",
    blurb := "A grow-only set: a map from elements to grow-only counters.",
    slots := ⟨"σ", "GSet σ", "SetInterp σ"⟩,
    recipe := principal "map_interpretation" #[gsetR], featured := true },
  { name := "2P-Set", code := "tpset σ",
    blurb := "A live set and a tombstone set. Once removed, an element cannot come back.",
    slots := ⟨"SetOp σ", "GSet σ × GSet σ", "SetInterp σ"⟩,
    recipe := principal "map_interpretation"
      #[derived "map_op" #[derived "disjoint_product" #[leaf "gset σ", leaf "gset σ"]]],
    featured := true },
  { name := "LWW-Element Set", code := "lww_element_set σ",
    blurb := "Timestamped adds and removes per element. A concurrent add and remove resolve to the add.",
    slots := ⟨"SetOp (Event τ σ)", "GSet (Event τ σ) × GSet (Event τ σ)", "SetInterp σ"⟩,
    recipe := principal "map_interpretation"
      #[derived "map_op" #[derived "disjoint_product" #[leaf "gset (Event τ σ)", leaf "gset (Event τ σ)"]]] },
  { name := "PN-Set", code := "pnset σ",
    blurb := "A counter per element: adds count up, removes count down, positive means present.",
    slots := ⟨"SetOp σ", "Associate σ Int", "SetInterp σ"⟩,
    recipe := principal "map_interpretation"
      #[derived "map_op" #[principal "associate σ" #[leaf "counter"]]], featured := true },
  { name := "OR-Set", code := "orset σ tok",
    blurb := "Adds carry unique tokens and removes cancel only the adds they observed, so concurrent adds survive.",
    slots := ⟨"OROp σ tok", "Finset (σ × tok) × Finset (σ × tok)", "Finset σ"⟩,
    recipe := principal "map_interpretation"
      #[derived "map_op" #[derived "disjoint_product" #[leaf "union_set (σ × tok)", leaf "union_set (σ × tok)"]]],
    featured := true },
  { name := "List", code := "POL.polist σ",
    blurb := "The paper's running example: nodes, insertion edges and tombstones, read in order by a traversal.",
    slots := ⟨"Insert σ ⊕ Remove σ", "(GSet σ × Associate σ (GSet σ)) × GSet σ", "List σ"⟩,
    recipe := principal "map_interpretation" #[derived "disjoint_product" #[
      derived "map_op" #[derived "joint_product" #[leaf "gset σ", poEdgesR]],
      derived "map_op" #[leaf "gset σ"]]],
    featured := true },
  { name := "List with Values", code := "polist_with_values χ c",
    blurb := "A list whose entries are themselves CRDTs, edited in place.",
    slots := ⟨"ValueListOp χ ω", "Associate χ σ × POListState χ", "List (χ × γ)"⟩,
    recipe := principal "map_interpretation" #[derived "map_op" #[derived "disjoint_product" #[
      principal "associate χ" #[leaf "c" .param],
      leaf "polist χ"]]],
    featured := true }
]

def findCrdt? (name : String) : Option CrdtInfo := crdts.find? (·.name == name)

def findCombinator? (name : String) : Option CombinatorInfo := combinators.find? (·.name == name)

/-! ## The paper -/

structure PaperInfo where
  title : String
  authors : Array String
  venue : String
  doi : String
  artifactDoi : String
  bibtex : String

def paper : PaperInfo where
  title := "Composing CRDTs Convergent by Construction"
  authors := #["Alexander Städing Dominguez", "George Zakhour", "Pascal Weisenburger", "Guido Salvaneschi"]
  venue := "Proc. ACM Program. Lang. 10, OOPSLA2, Article 346 (2026)"
  doi := "10.1145/3839478"
  artifactDoi := "10.5281/zenodo.21532005"
  bibtex := "@article{StadingDominguez2026Composing,
  title     = {Composing {CRDTs} Convergent by Construction},
  author    = {St{\\\"a}ding Dominguez, Alexander and Zakhour, George and
               Weisenburger, Pascal and Salvaneschi, Guido},
  journal   = {Proc. ACM Program. Lang.},
  volume    = {10},
  number    = {OOPSLA2},
  articleno = {346},
  year      = {2026},
  doi       = {10.1145/3839478}
}"

/-- The publications about crdtlib, newest first. They are listed on the Publications page. -/
def publications : Array PaperInfo := #[paper]

/-- How a construction uses a combinator, in the paper's dependency table. -/
inductive Use where
  | none
  /-- Applied directly in the definition. -/
  | direct
  /-- Used through another combinator. -/
  | transitive

/-- A row of the paper's table: which combinators a construction uses. -/
structure UsageRow where
  name : String
  /-- One entry per combinator, in the order of `combinators`. -/
  uses : String

/-- A table section with a heading. -/
structure UsageGroup where
  title : String
  rows : Array UsageRow

/--
The paper's Table 1. In `uses`, each character is one combinator, in the order of `combinators`:
`d` is direct use, `t` is transitive use, and `.` is no use.
-/
def usageTable : Array UsageGroup := #[
  { title := "Derived combinators", rows := #[
    ⟨"MapOp",            "...d....."⟩,
    ⟨"DisjointProduct",  "d..d....."⟩,
    ⟨"JointProduct",     "d..d....."⟩,
    ⟨"TaggedUnion",      "t..td.d.."⟩,
    ⟨"TaggedUnion3",     "td.tt.t.d"⟩] },
  { title := "Common CRDTs", rows := #[
    ⟨"2P-Set",                   "t.ttddd.."⟩,
    ⟨"LWW-Element Set",          "t.ttddd.."⟩,
    ⟨"PN-Set",                   "..dtdd..."⟩,
    ⟨"OR-Set",                   "t..tddd.."⟩,
    ⟨"Add-Remove Partial Order", "t.ttdddd."⟩] },
  { title := "Case studies", rows := #[
    ⟨"TicTacToe", "t.ddddd.."⟩,
    ⟨"JSON tree", "t.ddddddd"⟩] }
]

def Use.ofChar : Char → Use
  | 'd' => .direct
  | 't' => .transitive
  | _ => .none

end Shared
