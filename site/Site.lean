module

-- `main` needs the components' private implementations; see its documentation.
import all Shared.Cards
import all Shared.Layout
import all Shared.Diagrams
import all Docs.Components
import all Home.Hero
import all Home.Carousel
public import VersoBlog
public import Home.Home
public import Home.NotFound
public import Home.Publications
public import Home.Theme
public import Docs.Pages.Overview
public import Docs.Pages.GetStarted
public import Docs.Pages.Model
public import Docs.Pages.Combinators
public import Docs.Pages.Catalog

@[expose] public section

open Verso.Genre.Blog
open Verso.Genre.Blog.Site.Syntax

/-!
The site: the landing page (`Home`) at the root, the documentation (`Docs`) under `docs/`
(`Shared.docsDir`), and a 404 page. It serves the stylesheets and scripts in `site/static/`, and the
images in `assets/`.
-/

def crdtlibSite : Site :=
  site Home.Home /
    static "static" ← "site/static"
    static "assets" ← "assets"

    "docs" Docs.Pages.Overview /
      "get-started" Docs.Pages.GetStarted
      "model" Docs.Pages.Model
      "combinators" Docs.Pages.Combinators
      "catalog" Docs.Pages.Catalog

    "publications" Home.Publications

    "404" Home.NotFound

end

/--
Generates the site. It is public but not exposed: `blogMain` collects every registered component,
and `block_component` declares each component's implementation privately, which an exposed body
cannot refer to. The `import all`s above make those implementations visible here.
-/
public def main (args : List String) : IO UInt32 :=
  Verso.Genre.Blog.blogMain Home.theme crdtlibSite {} args
