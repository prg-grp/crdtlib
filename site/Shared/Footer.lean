import VersoBlog

import Shared.Brand
import Shared.Icons
import Shared.Data

open Verso.Output Html

namespace Shared
namespace Components

private def footerLink (label url : String) : Html := {{
  <li><a href={{ url }}>{{ label }}</a></li>
}}

def footer : Html := {{
  <footer class="site-footer">
    <div class="container footer-grid">
      <div class="footer-brand">
        <a class="brand" href="/">{{ wordmark }}</a>
        <p>
          "Composable, verified CRDTs in Lean 4. The library behind "
          <a href={{ s!"https://doi.org/{paper.doi}" }}><em>{{ paper.title }}</em></a> " (OOPSLA 2026)."
        </p>
      </div>
      <nav aria-label="Documentation">
        <h3>"Documentation"</h3>
        <ul>
          {{ footerLink "Overview" (docsUrl) }}
          {{ footerLink "Get started" (docsUrl "get-started") }}
          {{ footerLink "The model" (docsUrl "model") }}
          {{ footerLink "Combinators" (docsUrl "combinators") }}
          {{ footerLink "Catalog" (docsUrl "catalog") }}
        </ul>
      </nav>
      <nav aria-label="Source">
        <h3>"Source and publications"</h3>
        <ul>
          {{ footerLink "Repository" repoUrl }}
          {{ footerLink "Publications" "/publications/" }}
          {{ footerLink "Artifact" s!"https://doi.org/{paper.artifactDoi}" }}
          {{ footerLink "Rust bindings" s!"{repoUrl}/tree/master/bindings/rust" }}
          {{ footerLink "Issues" s!"{repoUrl}/issues" }}
        </ul>
      </nav>
      <nav aria-label="Lean">
        <h3>"Lean"</h3>
        <ul>
          {{ footerLink "Lean" "https://lean-lang.org/" }}
          {{ footerLink "Mathlib" "https://github.com/leanprover-community/mathlib4" }}
          {{ footerLink "Verso" "https://github.com/leanprover/verso" }}
        </ul>
      </nav>
    </div>
    <div class="container footer-bottom">
      <a href="https://programming-group.com">"Programming Group"</a>
      <p>"Built with " <a href="https://github.com/leanprover/verso">"Verso"</a> "."</p>
    </div>
  </footer>
}}

end Components
end Shared
