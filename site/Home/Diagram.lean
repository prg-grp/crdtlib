module

public import Shared
public import Home.Showcase

@[expose] public section

open Verso.Output Html
open Shared

/-!
# Construction diagrams

Lays out a slide's construction as a tree and draws it as SVG: the application at the top, the
outermost combinator below it, and the leaves at the bottom. `assets/js/showcase.js` animates it,
using the `data-*` attributes set here to find edges and nodes.

Coordinates are whole pixels in the SVG's own coordinate system; text widths are estimates for the
site's fonts.
-/

namespace Home
namespace Diagram

def boxH : Nat := 40
def levelH : Nat := 64
def gap : Nat := 12
def margin : Nat := 10
def appH : Nat := 32
/-- Vertical space above the root: the application box and the edge into the root. -/
def treeTop : Nat := appH + 32
def chipGap : Nat := 8
def chipH : Nat := 20
/-- How far `associate` offsets the stacked copies of its argument. -/
def stackOffset : Nat := 5

def codeW (s : String) : Nat := s.length * 78 / 10
def noteW (s : String) : Nat := s.length * 62 / 10
def chipW (s : String) : Nat := s.length * 68 / 10 + 18

def boxW (n : Node) : Nat := max 96 (max (codeW n.code) (noteW n.note) + 20)

/-- A node with its position: `x` is its center, `y` its top. `path` is the child indices from the root. -/
structure Placed where
  node : Node
  path : List Nat
  x : Nat
  y : Nat
  /-- The node's distance from its deepest leaf; the drawing assembles bottom-up in this order. -/
  height : Nat
  /-- The node is the argument of an `associate`. -/
  stacked : Bool

def pathKey (path : List Nat) : String := ".".intercalate (path.map toString)

/-- The widest state a leaf takes over the slide. -/
def stateWidth (steps : Array Step) (n : Node) : Nat :=
  steps.foldl (init := chipW n.state) fun w s =>
    s.hops.foldl (init := w) fun w h => if h.target == n.key then max w (chipW h.state) else w

/-- The state a leaf ends in after the slide's steps. Without JavaScript, the diagram shows it. -/
def finalState (steps : Array Step) (n : Node) : String :=
  steps.foldl (init := n.state) fun st s =>
    s.hops.foldl (init := st) fun st h => if h.target == n.key then h.state else st

partial def height (n : Node) : Nat :=
  n.children.foldl (fun h c => max h (height c + 1)) 0

/-- The width a subtree needs. -/
partial def width (steps : Array Step) (stacked : Bool := false) (n : Node) : Nat :=
  let own := boxW n + (if stacked then 2 * stackOffset else 0)
  if n.children.isEmpty then max own (stateWidth steps n)
  else
    let kids := n.children.map (width steps n.keyed)
    max own (kids.foldl (· + ·) 0 + gap * (kids.size - 1))

/-- Places a subtree whose left edge is at `left`. Returns the placed nodes, the root's last. -/
partial def place (steps : Array Step) (n : Node) (left depth : Nat) (path : List Nat)
    (stacked : Bool) : Array Placed := Id.run do
  let w := width steps stacked n
  let y := treeTop + depth * levelH
  if n.children.isEmpty then
    return #[{ node := n, path, x := left + w / 2, y, height := 0, stacked }]
  let kids := n.children.map (width steps n.keyed)
  let total := kids.foldl (· + ·) 0 + gap * (kids.size - 1)
  let mut cursor := left + (w - total) / 2
  let mut out := #[]
  let mut centers := #[]
  for h : i in [0:n.children.size] do
    let sub := place steps n.children[i] cursor (depth + 1) (path ++ [i]) n.keyed
    out := out ++ sub
    centers := centers.push (sub.back?.map (·.x) |>.getD cursor)
    cursor := cursor + kids[i]! + gap
  let x := (centers[0]! + centers.back!) / 2
  return out.push { node := n, path, x, y, height := height n, stacked }

/-- The path from the root to the leaf with the given key, if there is one. -/
partial def findPath (n : Node) (key : String) : Option (List Nat) :=
  if n.children.isEmpty then
    if n.key == key then some [] else none
  else
    (List.range n.children.size).findSome? fun i =>
      (findPath n.children[i]! key).map (i :: ·)

def edgePath (x₁ y₁ x₂ y₂ : Nat) : String :=
  let ym := (y₁ + y₂) / 2
  s!"M{x₁} {y₁} C{x₁} {ym} {x₂} {ym} {x₂} {y₂}"

def nodeSvg (steps : Array Step) (p : Placed) : Html :=
  let n := p.node
  let w := boxW n
  let leaf := n.children.isEmpty
  let final := finalState steps n
  -- A combinator's tool, on a tile pinned to the box's corner.
  let combinator := if leaf then none else Tools.combinatorOf n.code
  let tool : Html := match combinator with
    | some name => Tools.badge name #[("x", "-11"), ("y", "-11"), ("width", "22"), ("height", "22")]
    | none => .empty
  -- A combinator's box links to its section on the documentation's Combinators page.
  let reference := combinator.bind fun name =>
    (findCombinator? name).map fun c => (c.name, docsUrl "combinators" c.slug)
  let cls := s!"dg-node role-{n.role.cls}{if leaf then " leaf" else ""}{if p.stacked then " stacked" else ""}"
  let stack : Html :=
    if p.stacked then {{
      <rect class="dg-ghost" x=s!"{2 * stackOffset}" y=s!"{2 * stackOffset}" width={{ toString w }} height={{ toString boxH }}/>
      <rect class="dg-ghost" x=s!"{stackOffset}" y=s!"{stackOffset}" width={{ toString w }} height={{ toString boxH }}/>
    }} else .empty
  let chip : Html :=
    if leaf then {{
      <g class="dg-state" transform=s!"translate({w / 2} {boxH + chipGap + (if p.stacked then 2 * stackOffset else 0)})">
        <rect class="dg-state-bg" x=s!"-{chipW final / 2}" y="0" width={{ toString (chipW final) }} height={{ toString chipH }}/>
        <text class="dg-state-text" x="0" y="14" data-initial={{ n.state }}>{{ final }}</text>
      </g>
    }} else .empty
  let body : Html := {{
    <g class="dg-body">
      {{ stack }}
      <rect class="dg-box" width={{ toString w }} height={{ toString boxH }}/>
      <text class="dg-code" x={{ toString (w / 2) }} y="17">{{ n.code }}</text>
      <text class="dg-note" x={{ toString (w / 2) }} y="31">{{ n.note }}</text>
      {{ chip }}
      {{ tool }}
    </g>
  }}
  {{
    <g class={{ cls }} data-node={{ pathKey p.path }} style=s!"--h: {p.height}"
      transform=s!"translate({p.x - w / 2} {p.y})">
      {{ match reference with
        | some (name, url) => {{
            <a class="dg-link" href={{ url }} aria-label=s!"{name} reference">
              <title>"Go to reference"</title>
              {{ body }}
            </a>
          }}
        | none => body }}
    </g>
  }}

/-- The SVG for a slide, with an accessible description of the construction. -/
def svg (slide : Slide) (id : String) : Html := Id.run do
  let views := #[slide.view] ++ slide.steps.map (·.view)
  let appW := views.foldl (fun w v => max w (codeW s!"app reads {v}" + 24)) 160
  let treeW := width slide.steps false slide.tree
  let innerW := max treeW appW
  let W := innerW + 2 * margin
  let placed := place slide.steps slide.tree (margin + (innerW - treeW) / 2) 0 [] false
  let some root := placed.back? | return .empty
  let bottom := placed.foldl (init := 0) fun b p =>
    let extra := if p.node.children.isEmpty then chipGap + chipH else 0
    let ghost := if p.stacked then 2 * stackOffset else 0
    max b (p.y + boxH + extra + ghost)
  let H := bottom + margin
  let byPath : Std.HashMap String Placed := placed.foldl (fun m p => m.insert (pathKey p.path) p) {}
  -- An edge from each node to each of its children, keyed by the child's path.
  let edges := placed.filterMap fun p => do
    guard !p.path.isEmpty
    let parent ← byPath[pathKey p.path.dropLast]?
    pure {{
      <path class="dg-edge" data-edge={{ pathKey p.path }} style=s!"--h: {parent.height}"
        d={{ edgePath parent.x (parent.y + boxH) p.x p.y }}/>
    }}
  let appX := root.x - appW / 2
  let leaves := placed.filter (·.node.children.isEmpty) |>.map (·.node.code)
  return {{
    <svg class="dg" viewBox=s!"0 0 {W} {H}" width={{ toString W }} height={{ toString H }} style=s!"--w: {W}px"
      role="img" aria-labelledby=s!"{id}-title">
      <title id=s!"{id}-title">
        {{ s!"{slide.title}: {slide.expr}. Built from {", ".intercalate leaves.toList}." }}
      </title>
      <g class="dg-app" style=s!"--h: {root.height + 1}" transform=s!"translate({appX} 0)">
        <g class="dg-app-body">
          <rect class="dg-app-box" width={{ toString appW }} height={{ toString appH }}/>
          <text class="dg-app-label" x="12" y="21">"app reads"</text>
          <text class="dg-view" x="86" y="21" data-initial={{ slide.view }}>{{ views.back! }}</text>
        </g>
      </g>
      <path class="dg-edge dg-entry" data-edge="in" style=s!"--h: {root.height + 1}"
        d={{ edgePath root.x appH root.x root.y }}/>
      {{ edges }}
      {{ placed.reverse.map (nodeSvg slide.steps) }}
      <g class="dg-tokens"/>
    </svg>
  }}

end Diagram
end Home
