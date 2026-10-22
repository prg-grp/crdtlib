import VersoBlog

import Shared
import Docs.Theme

open Verso Genre Blog Template Output Html Multi
open Shared Theme Components

/-!
The theme of the whole site. The landing page and the 404 page lay themselves out with the
directives in `Shared.Layout`; the documentation pages use `Docs.pageTemplate`.
-/

namespace Home

def description : String :=
  "A Lean 4 library of operation-based CRDTs built from five principal combinators. " ++
  "Everything assembled from them converges by construction."

def headConfig (path : Path) : HeadConfig :=
  if Docs.isDocs path then Docs.headConfig
  else {
    rootTitle := s!"{siteName} · Composable, verified CRDTs"
    titleSuffix := siteName
    description
    social := { title := s!"{siteName} · Composable, verified CRDTs", description, url := repoUrl, siteName }
    stylesheets := #["css/home.css", "css/showcase.css"]
    base := if path == #["404"] then some "/" else none }

/--
The root-absolute URL of a page. In-page links need it: Verso's `<base>` element makes a bare
`#anchor` point at the site's root.
-/
def pageUrl (path : Path) : String :=
  "/" ++ String.join (path.toList.map (· ++ "/"))

/-- The header links. -/
def topItems (path : Path) : Array Item :=
  let docs := Docs.isDocs path
  let gettingStarted := Docs.docsPath path == #["get-started"]
  #[
    { title := "Docs", url := docsRoot, active := docs && !gettingStarted },
    { title := "Get started", url := docsUrl "get-started", active := docs && gettingStarted },
    { title := "Publications", url := "/publications/", active := path == #["publications"] }
  ]

private def primaryTemplate : TemplateM Html := do
  let path ← currentPath
  let docs := Docs.isDocs path
  return {{
    <html lang="en">
      {{ ← head (headConfig path) }}
      <body class={{ if docs then "docs" else "" }}>
        <a class="skip-link" href={{ pageUrl path ++ "#content" }}>"Skip to content"</a>
        <header class="site-header">
          {{ navBar (topItems path) (if docs then some ("Docs", docsRoot) else none) }}
        </header>
        <div id="content">{{ ← param "content" }}</div>
        {{ footer }}
        {{ if docs then {{ <script src="/static/js/toc.js"/> }} else {{ <script src="/static/js/showcase.js"/> }} }}
        <script src="/static/js/copy.js"/>
      </body>
    </html>
  }}

private def pageTemplate : TemplateM Html := do
  if Docs.isDocs (← currentPath) then Docs.pageTemplate
  else return {{ <main class="free">{{ ← param "content" }}</main> }}

/-- There are no blog posts, so post and category pages use Verso's defaults. -/
def theme : Theme :=
  { Theme.default with
    pageTemplate,
    primaryTemplate }

end Home
