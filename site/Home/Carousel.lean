module

public import VersoBlog
public import Shared.Directive
public import Shared
public import Home.Diagram
public import Home.Showcase

@[expose] public section

open Verso Genre Blog
open Verso.Output Html
open Lean (Json)
open Shared

/-!
The carousel on the landing page: one slide per construction in `Home.slides`, each with its
diagram and the operations played on it. Without JavaScript the slides are shown one below the
other, in their final state.
-/

namespace Home

/-- Renders `` `code` `` spans in a short text. -/
def inlineCode (s : String) : Html :=
  .seq <| (s.splitOn "`").toArray.mapIdx fun i (part : String) =>
    if i % 2 == 1 then {{ <code>{{ part }}</code> }} else Html.text true part

/-- The combinators a construction applies, outermost first, each once. -/
partial def combinatorsOf (n : Node) : Array (String × Role) :=
  let here := if n.children.isEmpty then #[] else #[((n.code.splitOn " ")[0]!, n.role)]
  n.children.foldl (init := here) fun acc c =>
    (combinatorsOf c).foldl (init := acc) fun acc x =>
      if acc.any (·.1 == x.1) then acc else acc.push x

/--
What each node reads as after `step`, given the leaves' states: the interpretation of its state,
computed bottom-up as `Step` describes. Returns what `n` reads as, and the same for every node below
it, by path.
-/
partial def interpretations (slide : Slide) (step : Step) (states : Std.HashMap String String)
    (n : Node) (path : List Nat) : Except String (String × Array (String × String)) := do
  let mut below := #[]
  let mut parts := #[]
  for h : i in [0:n.children.size] do
    let (g, rest) ← interpretations slide step states n.children[i] (path ++ [i])
    parts := parts.push g
    below := below ++ rest
  let head := (n.code.splitOn " ")[0]!
  let derived : Option String :=
    if n.children.isEmpty then some (states.getD n.key n.state)
    else match head with
      | "disjoint_product" | "joint_product" | "product" => some s!"({", ".intercalate parts.toList})"
      | "map_op" | "traverse" | "associate" | "map_state" => parts[0]?
      | _ => none
  let g ←
    if let some g := step.reads.lookup n.key then pure g
    else if path.isEmpty then
      -- The root reads as what the application reads. If its interpretation changes nothing, the
      -- construction below it must already produce that.
      match derived with
      | some g =>
        if g != step.view && head != "map_interpretation" then
          throw s!"slide '{slide.tab}': after `{step.op}`, the root reads as '{g}' but the view is '{step.view}'"
        pure step.view
      | none => pure step.view
    else match derived with
      | some g => pure g
      | none => throw s!"slide '{slide.tab}': say what `{n.code}` reads as after `{step.op}`"
  return (g, below.push (Diagram.pathKey path, g))

/-- The steps of a slide for the script, with each delivery's path through the tree. -/
def stepsJson (slide : Slide) : Except String Json := do
  let mut states : Std.HashMap String String := {}
  let mut out := #[]
  for step in slide.steps do
    for hop in step.hops do
      states := states.insert hop.target hop.state
    let (_, reads) ← interpretations slide step states slide.tree []
    out := out.push (step, reads)
  let steps ← out.mapM fun (step, reads) => do
    let hops ← step.hops.mapM fun hop => do
      let some path := Diagram.findPath slide.tree hop.target
        | throw s!"slide '{slide.tab}': no leaf '{hop.target}'"
      if path.length != hop.labels.length then
        throw s!"slide '{slide.tab}': the operation to '{hop.target}' crosses {path.length} edges below the root, but has {hop.labels.length} labels"
      pure <| Json.mkObj [
        ("path", Lean.toJson path),
        ("labels", Json.arr (hop.labels.toArray.map Json.str)),
        ("state", Json.str hop.state)]
    pure <| Json.mkObj [("op", Json.str step.op), ("view", Json.str step.view), ("hops", Json.arr hops),
      ("reads", Json.mkObj (reads.toList.map fun (k, g) => (k, Json.str g)))]
  return Json.arr steps

def slideHtml (count : Nat) (i : Nat) (slide : Slide) : Except String Html := do
  let steps ← stepsJson slide
  let id := s!"slide-{i + 1}"
  let (refName, refUrl) := slide.reference
  return {{
    <article class=s!"sc-slide{if i == 0 then " active" else ""}" id={{ id }} role="tabpanel"
      aria-roledescription="slide" aria-label=s!"{i + 1} of {count}: {slide.title}"
      data-steps={{ steps.compress }}>
      <div class="sc-copy">
        <p class="kicker">{{ slide.kicker }}</p>
        <h3 class="sc-title">{{ slide.title }}</h3>
        <p class="sc-blurb">{{ inlineCode slide.blurb }}</p>
        <code class="sc-expr">{{ slide.expr }}</code>
        <ol class="sc-ops" aria-label="Operations">
          {{ slide.steps.map fun s => {{
              <li class="done"><code class="sc-op">{{ s.op }}</code><span class="sc-arrow">"→"</span><code class="sc-op-view">{{ s.view }}</code></li>
            }} }}
        </ol>
        <ul class="sc-uses" aria-label="Combinators">
          {{ (combinatorsOf slide.tree).map fun (name, role) => {{
              <li class=s!"chip role-{role.cls}">
                {{ (Tools.combinatorOf name).map (Tools.badge · #[("width", "20"), ("height", "20")]) |>.getD .empty }}
                {{ name }}
              </li>
            }} }}
        </ul>
        <p class="sc-meta">
          <a href={{ refUrl }}>{{ refName }} " Reference" {{ Icons.arrowRight }}</a>
        </p>
      </div>
      <figure class="sc-figure">
        {{ Diagram.svg slide id }}
      </figure>
    </article>
  }}

/-- The colors of the diagrams. -/
def legend : Html := {{
  <ul class="legend sc-legend" aria-label="Legend">
    <li><span class="swatch rc-principal"/>"Principal combinator"</li>
    <li><span class="swatch rc-derived"/>"Derived combinator"</li>
    <li><span class="swatch rc-primitive"/>"Primitive CRDT"</li>
    <li><span class="swatch rc-param"/>"CRDT built elsewhere from combinators"</li>
    <li><span class="token-swatch op">"ω"</span>"Operation"</li>
    <li><span class="token-swatch interp">"γ"</span>"Interpretation of the state"</li>
  </ul>
}}

/--
The carousel, under a short introduction: `title` in the left column, and the directive's contents
in the right one.
-/
block_component showcase (title : String) where
  toHtml _ _ _ goB contents := do
    let mut rendered := #[]
    for h : i in [0:slides.size] do
      match slideHtml slides.size i slides[i] with
      | .ok html => rendered := rendered.push html
      | .error e => Verso.reportError s!"showcase: {e}"
    let tabs := slides.mapIdx fun i s => {{
      <button class=s!"sc-tab{if i == 0 then " active" else ""}" type="button" role="tab"
        id=s!"tab-{i + 1}" aria-controls=s!"slide-{i + 1}" aria-selected={{ if i == 0 then "true" else "false" }}
        tabindex={{ if i == 0 then "0" else "-1" }}>
        <span class="sc-tab-label">{{ s.tab }}</span>
        <span class="sc-tab-progress" aria-hidden="true"/>
      </button>
    }}
    return {{
      <section class="showcase" id="showcase" aria-roledescription="carousel" aria-label="Constructions">
        <div class="container">
          <div class="sc-intro">
            <h2 class="sc-intro-title">{{ title }}</h2>
            <div class="sc-intro-text">{{ ← contents.mapM goB }}</div>
          </div>
          <div class="sc-head">
            <div class="sc-tabs" role="tablist" aria-label="Constructions">{{ tabs }}</div>
            <div class="sc-controls">
              <button class="icon-button sc-prev" type="button" aria-label="Previous construction">{{ Icons.chevronLeft }}</button>
              <button class="icon-button sc-play" type="button" aria-label="Pause the animation">
                <span class="when-playing">{{ Icons.pause }}</span>
                <span class="when-paused">{{ Icons.play }}</span>
              </button>
              <button class="icon-button sc-next" type="button" aria-label="Next construction">{{ Icons.chevronRight }}</button>
            </div>
          </div>
          <div class="sc-stage">{{ rendered }}</div>
          {{ legend }}
        </div>
      </section>
    }}

block_directive showcase (title : String)

end Home
