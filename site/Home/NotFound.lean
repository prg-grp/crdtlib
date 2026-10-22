module

public import VersoBlog
public import Shared

@[expose] public section

open Verso.Genre.Blog (Page blob)
open Verso.Output Html
open Shared

def notFound : Html := {{
  <section class="not-found container">
    <p class="kicker">"404"</p>
    <h1>"This replica never received that page."</h1>
    <p>"It may have moved, or the link may be wrong."</p>
    <div class="actions">
      <a class="button primary" href="/">"Back to the start"</a>
      <a class="button secondary" href={{ docsRoot }}>"Read the docs"</a>
    </div>
  </section>
}}

#doc (Page) "Not Found" =>

%%%
showInNav := false
%%%

:::blob notFound
:::
