module

public import VersoBlog
public import Shared
public import Home.Carousel
public import Home.Hero

@[expose] public section

open Verso.Genre.Blog (Page)
open Verso.Code.External

-- Code excerpts are read from the library's modules, between `-- ANCHOR:` comments.
set_option verso.exampleProject "."

#doc (Page) "Home" =>

:::Home.hero
:::

:::Home.showcase "Examples"
Each tab below is a CRDT assembled from the combinators.
Watch an operation travel down through the construction, transform at each combinator,
and the interpreted state come back up to the application.
:::

::::::Shared.band "model" "The model" "The CRDT Type"
:::::Shared.split "code-right"
::::Shared.col
Replicas apply operations as they arrive, in whatever order the network delivers them.
A CRDT defines what an operation does to the local state, and what the application reads from it.

* `effect` applies an operation to the state `σ`.
* `interpret` turns the state into the _interpreted state_ `γ` for the application.
* `commutative` guarantees that events can be applied in any order and produce the same state.

Replicas that have seen the same operations end in the same state, without coordination: _strong eventual consistency_.

[Read about the model →](/docs/model/)
::::
::::Shared.col
```anchor CRDTt (module := Crdtlib.CRDT.Basic)
structure CRDTₜ (τ : Type) [PartialOrder τ] (ω σ γ : Type*) where
  effect : Event τ ω → σ → σ
  interpret : σ → γ
  commutative : ∀ (e₁ e₂ : Event τ ω),
    Concurrent e₁.t e₂.t → (effect e₂) ∘ (effect e₁) = (effect e₁) ∘ (effect e₂)
```
::::
:::::
::::::

::::::Shared.band "convergence" "Convergent by construction" "Compose without a convergence proof burden"
:::::Shared.split "even"
::::Shared.col
:::Shared.convergence
:::
::::
::::Shared.col
Writing a CRDT by hand means proving `commutative` for the whole data type,
and every change to it means proving it again.

Instead, each combinator automatically constructs a proof of commutativity (and thus convergence) for each constructed CRDT.
This holds for any level of nesting, since the CRDT type carries the commutativity proof.

::::
:::::
::::::

::::::Shared.band "combinators" "Composition" "Combinators"
:::Shared.subheading "Principal"
:::

:::Shared.combinatorGrid "principal"
:::

:::Shared.subheading "Derived"
:::

:::Shared.combinatorGrid "derived"
:::

[All combinators in the docs →](/docs/combinators/)
::::::

::::::Shared.band "next" "Next steps" "Compose your first CRDT."
:::Shared.actions "Get started|/docs/get-started/;Read the docs|/docs/;Browse the catalog|/docs/catalog/"
:::
::::::
