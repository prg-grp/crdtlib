module

public import VersoBlog
public import Shared.Directive
public import Shared.Brand
public import Shared.Data
public import Shared.Tools

@[expose] public section

open Verso Genre Blog
open Verso.Output Html

/-!
Renderers for the site data: recipes (nested boxes), type slots (`ω σ γ`), and cards.
-/

namespace Shared

/-- A recipe as nested boxes. Each combinator box contains the CRDTs it is applied to. -/
partial def Recipe.toHtml : Recipe → Html
  | .leaf code role => {{
      <span class=s!"rc-leaf rc-{role.cls}"><code>{{ code }}</code></span>
    }}
  | .node code role args => {{
      <div class=s!"rc rc-{role.cls}">
        <div class="rc-head"><code>{{ code }}</code></div>
        <div class="rc-body">{{ args.map Recipe.toHtml }}</div>
      </div>
    }}

/--
The type parameters of a CRDT as three labelled slots. Slots in `changes` are highlighted.
-/
def Slots.toHtml (s : Slots) (changes : List String := []) : Html :=
  let slot (sym title ty : String) : Html := {{
    <span class=s!"slot{if changes.contains sym then " on" else ""}" title={{title}}>
      <span class="slot-sym">{{ sym }}</span>
      <code class="slot-ty">{{ ty }}</code>
    </span>
  }}
  {{
    <div class="slots">
      {{ slot "ω" "operations" s.ω }}
      {{ slot "σ" "state" s.σ }}
      {{ slot "γ" "what readers observe" s.γ }}
    </div>
  }}

def roleLabel : Role → String
  | .principal => "Principal"
  | .derived => "Derived"
  | .primitive => "Primitive"
  | .param => "Parameter"

def CombinatorInfo.card (c : CombinatorInfo) : Html := {{
  <a class=s!"card comb-card role-{c.role.cls}" href={{ docsUrl "combinators" c.slug }}>
    <div class="comb-head">
      <span class="role-tag">{{ roleLabel c.role }}</span>
      {{ Tools.badge c.name }}
    </div>
    <h3>{{ c.name }}</h3>
    <code class="usage">{{ c.usage }}</code>
    <p>{{ c.blurb }}</p>
    {{ c.result.toHtml c.changes }}
  </a>
}}

def CrdtInfo.card (c : CrdtInfo) : Html := {{
  <a class="card crdt-card" href={{ docsUrl "catalog" c.slug }}>
    <div class="crdt-head">
      <h3>{{ c.name }}</h3>
      <code>{{ c.code }}</code>
    </div>
    <p>{{ c.blurb }}</p>
    <div class="recipe">{{ c.recipe.toHtml }}</div>
  </a>
}}

def legend : Html := {{
  <ul class="legend" aria-label="Legend">
    <li><span class="swatch rc-principal"/>"Principal combinator"</li>
    <li><span class="swatch rc-derived"/>"Derived combinator"</li>
    <li><span class="swatch rc-primitive"/>"Primitive CRDT"</li>
  </ul>
}}

/-- Cards for the combinators with the given role (`principal` or `derived`). -/
block_component combinatorGrid (role : String) where
  toHtml _ _ _ _ _ := do
    let cs := combinators.filter (·.role.cls == role)
    if cs.isEmpty then Verso.reportError s!"combinatorGrid: no combinators with role '{role}'"
    return {{ <div class="card-grid comb-grid">{{ cs.map (·.card) }}</div> }}

block_directive combinatorGrid (role : String)

/-- Cards for the catalog: `featured` for the home page, `all` for everything. -/
block_component crdtGrid (which : String) where
  toHtml _ _ _ _ _ := do
    let cs := if which == "all" then crdts else crdts.filter (·.featured)
    return {{ <div class="card-grid crdt-grid">{{ cs.map (·.card) }}</div> }}

block_directive crdtGrid (which : String)

/-- The recipe and type parameters of one CRDT from the catalog, by display name. -/
block_component recipe (name : String) where
  toHtml _ _ _ _ _ := do
    let some c := findCrdt? name
      | Verso.reportError s!"recipe: unknown CRDT '{name}'"; return .empty
    return {{
      <figure class="recipe-figure">
        <div class="recipe">{{ c.recipe.toHtml }}</div>
        <figcaption>{{ c.slots.toHtml }}</figcaption>
      </figure>
    }}

block_directive recipe (name : String)

/-- How a combinator changes the type parameters, by its paper name. -/
block_component combinatorSignature (name : String) where
  toHtml _ _ _ _ _ := do
    let some c := findCombinator? name
      | Verso.reportError s!"combinatorSignature: unknown combinator '{name}'"; return .empty
    return {{
      <div class=s!"signature role-{c.role.cls}">
        {{ Tools.badge c.name }}
        <span class="role-tag">{{ roleLabel c.role }}</span>
        <code class="usage">{{ c.usage }}</code>
        <span class="signature-arrow">"produces"</span>
        {{ c.result.toHtml c.changes }}
      </div>
    }}

block_directive combinatorSignature (name : String)

block_component recipeLegend where
  toHtml _ _ _ _ _ := pure legend

block_directive recipeLegend

private def useCell : Use → Html
  | .direct => {{ <td><span class="use direct" title="used directly">"●"</span></td> }}
  | .transitive => {{ <td><span class="use transitive" title="used through another combinator">"○"</span></td> }}
  | .none => {{ <td><span class="use none" aria-label="not used"/></td> }}

/-- The paper's table of which combinators each construction uses. -/
block_component usageMatrix where
  toHtml _ _ _ _ _ := do
    for g in usageTable do
      for r in g.rows do
        if r.uses.length != combinators.size then
          Verso.reportError s!"usageMatrix: row '{r.name}' has {r.uses.length} entries, expected {combinators.size}"
    let head := combinators.map fun c => {{
      <th scope="col" class=s!"col-comb role-{c.role.cls}"><span>{{ c.name }}</span></th>
    }}
    let groups := usageTable.map fun g => {{
      <tbody>
        <tr class="group"><th scope="rowgroup" colspan=s!"{combinators.size + 1}">{{ g.title }}</th></tr>
        {{ g.rows.map fun r => {{
            <tr>
              <th scope="row">{{ r.name }}</th>
              {{ r.uses.toList.toArray.map (useCell ∘ Use.ofChar) }}
            </tr>
          }} }}
      </tbody>
    }}
    return {{
      <figure class="usage-figure">
        <div class="table-scroll">
          <table class="usage-table">
            <thead>
              <tr>
                <th scope="col" class="col-name">"Construction"</th>
                {{ head }}
              </tr>
            </thead>
            {{ groups }}
          </table>
        </div>
        <figcaption>
          <span class="use direct">"●"</span> " used directly, "
          <span class="use transitive">"○"</span> " used through another combinator. "
        </figcaption>
      </figure>
    }}

block_directive usageMatrix

/-- A publication in the list: venue, title, authors, links, and a BibTeX entry to expand. -/
def PaperInfo.listItem (p : PaperInfo) : Html := {{
  <li class="pub">
    <p class="pub-venue">{{ p.venue }}</p>
    <h3 class="pub-title"><a href={{ s!"https://doi.org/{p.doi}" }}>{{ p.title }}</a></h3>
    <p class="pub-authors">{{ ", ".intercalate p.authors.toList }}</p>
    <div class="actions">
      <a class="button secondary" href={{ s!"https://doi.org/{p.doi}" }}>"Paper"</a>
      <a class="button secondary" href={{ s!"https://doi.org/{p.artifactDoi}" }}>"Artifact"</a>
    </div>
    <details class="bibtex">
      <summary>"BibTeX"</summary>
      <pre>{{ p.bibtex }}</pre>
    </details>
  </li>
}}

/-- Every publication in `publications`. -/
block_component publicationList where
  toHtml _ _ _ _ _ := pure {{ <ol class="pub-list">{{ publications.map (·.listItem) }}</ol> }}

block_directive publicationList

end Shared
