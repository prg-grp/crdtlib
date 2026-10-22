import VersoBlog

open Verso.Output Html

namespace Shared

/-- The project's name as shown on the sites. Change it here to rename them. -/
def siteName : String := "crdtlib"

def repoUrl : String := "https://github.com/prg-grp/crdtlib"

/-- The directory of the site that holds the documentation pages. -/
def docsDir : String := "docs"

/-- Where the documentation pages are served. -/
def docsRoot : String := s!"/{docsDir}/"

/-- The URL of a documentation page, optionally with an anchor: `docsUrl "catalog" "or-set"`. -/
def docsUrl (page : String := "") (anchor : String := "") : String :=
  let page := if page.isEmpty then "" else s!"{page}/"
  let anchor := if anchor.isEmpty then "" else s!"#{anchor}"
  s!"{docsRoot}{page}{anchor}"

namespace Components

/--
The logo, from `assets/logo.svg`, its only source, which is also the favicon. It is read when this
module is compiled: after changing the file, rebuild with `lake build Shared.Brand`.
-/
def logoMark : Html := {{
  <span class="logo-mark" aria-hidden="true">{{ Html.text false (include_str "../../assets/logo.svg") }}</span>
}}

def wordmark : Html := {{
  <span class="wordmark">{{ logoMark }}<span class="wordmark-text">{{ siteName }}</span></span>
}}

end Components
end Shared
