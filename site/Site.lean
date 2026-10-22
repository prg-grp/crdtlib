import VersoBlog

import Home.Home
import Home.NotFound
import Home.Publications
import Home.Theme
import Docs.Pages.Overview
import Docs.Pages.GetStarted
import Docs.Pages.Model
import Docs.Pages.Combinators
import Docs.Pages.Catalog

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

def main (args : List String) : IO UInt32 :=
  blogMain Home.theme crdtlibSite {} args
