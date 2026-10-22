module

public import VersoBlog
public import Shared.Directive
public import Shared

@[expose] public section

open Verso Genre Blog
open Verso.Output Html
open Shared

namespace Home

block_component hero where
  toHtml _ _ _ _ _ := do
    return {{
      <section class="hero" aria-label="Introduction">
        <div class="container hero-inner">
          <h1>"Composable CRDTs"<br/>"Convergent by Construction"</h1>
          <p class="hero-lede">
            {{ siteName }} " is a "<a href="https://lean-lang.org">"Lean 4"</a>" library "
            "with reusable combinators that can be used to construct conflict-free replicated data types "
            "without needing to prove convergence at every step. "
            "The combinators each preserve convergence, so whatever you assemble from them is a CRDT by construction: "
            "verified in Lean and executable."
          </p>
          <div class="actions">
            <a class="button primary" href={{ docsUrl "get-started" }}>"Get started" {{ Icons.arrowRight }}</a>
            <a class="button secondary" href={{ docsRoot }}>"Read the docs"</a>
            <a class="button ghost" href={{ repoUrl }}>{{ Icons.github }} "Source"</a>
          </div>
        </div>
      </section>
    }}

block_directive hero

end Home
