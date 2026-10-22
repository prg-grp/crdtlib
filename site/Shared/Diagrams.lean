import VersoBlog

open Verso Genre Blog
open Verso.Output Html

namespace Shared

/--
Two replicas apply the concurrent operations `add x` and `add y` in different orders and end in
the same state, from `assets/figures/convergence.svg`. It is included in the page as it is, so that
its colors come from CSS and follow the theme.
-/
def convergenceSvg : Html := .text false (include_str "../../assets/figures/convergence.svg")

block_component +directive convergence where
  toHtml _ _ _ _ _ := do
    return {{
      <figure class="figure">
        {{ convergenceSvg }}
        <figcaption>
          "Replica A applies " <code>"add x"</code> " then " <code>"add y"</code> "; replica B the reverse. "
          "The two operations are concurrent, so " <code>"commutative"</code> " guarantees that applying them in both orders result in the same state."
        </figcaption>
      </figure>
    }}

end Shared
