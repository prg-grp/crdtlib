module

public import VersoBlog

@[expose] public section

open Verso.Output Html

/-!
# Tools

A tool for each combinator, drawn on a 48×48 grid in `assets/tools/`:

| Combinator | Tool | Why |
|---|---|---|
| Product | bar clamp | holds two parts, so every operation reaches both |
| MapState | hand plane | reshapes the state without changing what it holds |
| Associate | cabinet of labelled drawers | one copy per key |
| Traverse | handsaw | cuts one operation into several |
| MapInterpretation | brush | the same state, seen differently |
| MapOp | router | routes each operation |
| DisjointProduct | two boards side by side | two parts, each operation on one |
| JointProduct | dovetail joint | two parts, joined in every operation |
| TaggedUnion | claw hammer | one tool, two ends |

The colors are classes (`t-main`, `t-light`, `t-steel`, …) defined in `base.css`. The main parts
take the color of the combinator's role (principal or derived) from the surrounding element, and
the drawing sits on a square tile.

The drawings are included in the page as they are, so that the site's CSS colors them. They are
read when this module is compiled: after changing one, rebuild with `lake build Shared.Tools`.
-/

namespace Shared
namespace Tools

/-- The tool for a combinator, by the name the paper uses. -/
def drawing : String → Option Html
  | "Product" => some <| .text false (include_str "../../assets/tools/product.svg")
  | "MapState" => some <| .text false (include_str "../../assets/tools/map-state.svg")
  | "Associate" => some <| .text false (include_str "../../assets/tools/associate.svg")
  | "Traverse" => some <| .text false (include_str "../../assets/tools/traverse.svg")
  | "MapInterpretation" => some <| .text false (include_str "../../assets/tools/map-interpretation.svg")
  | "MapOp" => some <| .text false (include_str "../../assets/tools/map-op.svg")
  | "DisjointProduct" => some <| .text false (include_str "../../assets/tools/disjoint-product.svg")
  | "JointProduct" => some <| .text false (include_str "../../assets/tools/joint-product.svg")
  | "TaggedUnion" => some <| .text false (include_str "../../assets/tools/tagged-union.svg")
  | _ => none

/-- The combinator that a Lean expression applies, from its first word: `map_op …` is `MapOp`. -/
def combinatorOf (code : String) : Option String :=
  match (code.splitOn " ")[0]! with
  | "product" => some "Product"
  | "map_state" => some "MapState"
  | "associate" | "associateₜ" => some "Associate"
  | "traverse" | "traverseₜ" => some "Traverse"
  | "map_interpretation" | "map_interpretationₜ" => some "MapInterpretation"
  | "map_op" | "map_opₜ" => some "MapOp"
  | "disjoint_product" | "disjoint_productₜ" => some "DisjointProduct"
  | "joint_product" | "joint_productₜ" => some "JointProduct"
  | "tagged_union" | "tagged_unionₜ" | "auto_tagged_unionₜ" => some "TaggedUnion"
  | _ => none

/--
A combinator's tool on a square tile, as a standalone `<svg>`. `attrs` are added to the `<svg>`
element, for example a position inside a larger drawing.
-/
def badge (name : String) (attrs : Array (String × String) := #[]) : Html :=
  match drawing name with
  | none => .empty
  | some tool =>
    .tag "svg" (#[("class", "tool"), ("viewBox", "0 0 64 64"), ("aria-hidden", "true")] ++ attrs) {{
      <rect class="t-tile" x="1" y="1" width="62" height="62"/>
      <g transform="translate(8 8)">{{ tool }}</g>
    }}

end Tools
end Shared
