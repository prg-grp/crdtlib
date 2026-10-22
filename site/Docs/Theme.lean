module

public import VersoBlog
public import Shared
public import Docs.Toc

@[expose] public section

open Verso Genre Blog Template Output Html Multi
open Shared Theme Components

/-!
The layout of the documentation pages, under `docsRoot`: a sidebar with every page, the article,
and links to the previous and next pages. `Home.Theme` uses it for every page in `docsDir`.
-/

namespace Docs

/-- Whether a page of the site is a documentation page. -/
def isDocs (path : Path) : Bool := path[0]? == some docsDir

/-- A page's path within the documentation: `#["docs", "model"]` is `#["model"]`. -/
def docsPath (path : Path) : Path := path.extract 1 path.size

/-- A documentation page in the sidebar. -/
structure NavPage where
  title : String
  url : String
  /-- The page's path within the documentation. -/
  path : Path

/-- Sidebar groups. Pages in no group are left out of the sidebar. -/
def groupOf : Path → Option String
  | #[] | #["get-started"] => some "Start here"
  | #["model"] => some "Concepts"
  | #["combinators"] | #["catalog"] => some "Reference"
  | _ => none

/-- The documentation pages, in site order, starting with the overview. -/
def navPages : TemplateM (Array NavPage) := do
  let .page _ _ top := (← read).site | return #[]
  let some (txt, subs) := top.findSome? fun
      | .page name _ txt subs => if name == docsDir then some (txt, subs) else none
      | _ => none
    | return #[]
  let pages := subs.filterMap fun
    | .page name _ txt .. =>
      if txt.metadata.map (·.showInNav) |>.getD true then
        some { title := txt.titleString, url := docsUrl name, path := #[name] }
      else none
    | _ => none
  return #[{ title := txt.titleString, url := docsRoot, path := #[] }] ++ pages

def description : String :=
  s!"Documentation for {siteName}, a Lean 4 library of operation-based CRDTs built from five " ++
  "principal combinators."

def headConfig : HeadConfig where
  rootTitle := s!"Documentation · {siteName}"
  titleSuffix := s!"{siteName} docs"
  description
  social := { title := s!"{siteName} documentation", description, url := repoUrl, siteName }
  stylesheets := #["css/doc.css"]

/--
The sidebar: every page, grouped, with the sections of the current page under it. On narrow
screens it collapses into a menu above the article.
-/
def sidebar (pages : Array NavPage) (current : Path) (sections : Option Html) : Html := Id.run do
  let mut groups : Array (String × Array NavPage) := #[]
  for p in pages do
    let some g := groupOf p.path | continue
    match groups.findIdx? (·.1 == g) with
    | some i => groups := groups.modify i fun (g, ps) => (g, ps.push p)
    | none => groups := groups.push (g, #[p])
  let currentTitle := pages.find? (·.path == current) |>.map (·.title) |>.getD "Contents"
  let entry (p : NavPage) : Html :=
    let here := p.path == current
    {{
      <li class={{ if here then "here" else "" }}>
        <a href={{ p.url }} aria-current={{ if here then "page" else "false" }}>{{ p.title }}</a>
        {{ if here then sections.getD .empty else .empty }}
      </li>
    }}
  return {{
    <aside class="doc-sidebar">
      <details class="doc-nav-toggle" open="open">
        <summary><span class="doc-nav-label">"Contents"</span><span class="doc-nav-current">{{ currentTitle }}</span></summary>
        <nav class="doc-nav" aria-label="Documentation">
          {{ groups.map fun (g, ps) => {{
              <p class="doc-nav-group">{{ g }}</p>
              <ul>{{ ps.map entry }}</ul>
            }} }}
        </nav>
      </details>
    </aside>
  }}

/-- Links to the neighbouring pages in sidebar order. -/
def pager (pages : Array NavPage) (current : Path) : Html := Id.run do
  let some i := pages.findIdx? (·.path == current) | return .empty
  let link (cls label : String) : Option NavPage → Html
    | some p => {{
        <a class=s!"pager-link {cls}" href={{ p.url }}>
          <span>{{ label }}</span><strong>{{ p.title }}</strong>
        </a>
      }}
    | none => {{ <span class=s!"pager-link {cls} empty"/> }}
  let prev := if i == 0 then none else pages[i - 1]?
  return {{
    <nav class="pager" aria-label="Pages">
      {{ link "prev" "Previous" prev }}
      {{ link "next" "Next" pages[i + 1]? }}
    </nav>
  }}

/-- The small line above a page's title. -/
def kicker (path : Path) : String := groupOf path |>.getD "Documentation"

/-- A documentation page. -/
def pageTemplate : TemplateM Html := do
  let content ← param "content"
  let path := docsPath (← currentPath)
  let pages ← navPages
  let pageUrl := pages.find? (·.path == path) |>.map (·.url) |>.getD docsRoot
  let sections := collectH1 content pageUrl
  return {{
    <main class="doc">
      <div class="container doc-grid">
        {{ sidebar pages path sections }}
        <article class="doc-main">
          <header class="doc-header">
            <p class="kicker">{{ kicker path }}</p>
            <h1>{{ ← param "title" }}</h1>
          </header>
          <div class="prose">{{ addSlug content }}</div>
          {{ pager pages path }}
        </article>
      </div>
    </main>
  }}

end Docs
