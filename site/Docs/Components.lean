module

public import VersoBlog
public import Shared.Directive
public import Shared

@[expose] public section

open Verso Genre Blog
open Verso.Output Html
open Shared

/-!
Components used only by the documentation.
-/

namespace Docs

/-- A documentation page, as shown on the overview. -/
structure Guide where
  title : String
  page : String
  kicker : String
  blurb : String

def guides : Array Guide := #[
  { title := "Get started", page := "get-started", kicker := "Start here",
    blurb := "Add the dependency, compose a CRDT from library parts, check that replicas converge, and write your own primitive." },
  { title := "The model", page := "model", kicker := "Concepts",
    blurb := "The system model, strong eventual consistency, what a CRDT is in Lean, and why composites need no new proofs." },
  { title := "Combinators", page := "combinators", kicker := "Reference",
    blurb := "The prinicpal and derived combinators that facilitate convergence by construction" },
  { title := "Catalog", page := "catalog", kicker := "Reference",
    blurb := "Registers, sets and the list CRDT, each with its construction, its definition, and the combinators it uses." }
]

/-- Cards linking to the documentation pages. -/
block_component guideCards where
  toHtml _ _ _ _ _ := do
    return {{
      <div class="card-grid guide-grid">
        {{ guides.map fun g => {{
            <a class="card guide-card" href={{ docsUrl g.page }}>
              <span class="guide-kicker">{{ g.kicker }}</span>
              <h3>{{ g.title }}</h3>
              <p>{{ g.blurb }}</p>
              <span class="guide-more">"Read" {{ Icons.arrowRight }}</span>
            </a>
          }} }}
      </div>
    }}

block_directive guideCards

/-- Where the library's modules are, for readers who want to follow along in the source. -/
def sourceMap : Array (String × String) := #[
  ("Crdtlib/CRDT/Basic.lean", "CRDT and CRDTₜ, and the conversion between them"),
  ("Crdtlib/CRDT/Pkg.lean, Concurrent.lean", "Events, timestamps and concurrency"),
  ("Crdtlib/CRDT/Primitive/", "The primitive families: ac_fun and mv_regₜ"),
  ("Crdtlib/Combinator/Principal/", "Product, MapState, Associate, Traverse, MapInterpretation"),
  ("Crdtlib/Combinator/Derived/", "MapOp, DisjointProduct, JointProduct, TaggedUnion"),
  ("Crdtlib/CRDT/Std/", "The catalog: registers, counters, sets and lists")
]

block_component sourceTable where
  toHtml _ _ _ _ _ := do
    return {{
      <div class="table-scroll">
        <table class="source-table">
          <thead><tr><th scope="col">"Path"</th><th scope="col">"Contents"</th></tr></thead>
          <tbody>
            {{ sourceMap.map fun (path, what) => {{
                <tr>
                  <td><a href=s!"{repoUrl}/tree/master/{(path.splitOn ",")[0]!}"><code>{{ path }}</code></a></td>
                  <td>{{ what }}</td>
                </tr>
              }} }}
          </tbody>
        </table>
      </div>
    }}

block_directive sourceTable

end Docs
