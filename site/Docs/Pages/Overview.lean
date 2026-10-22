module

public import VersoBlog
public import Shared
public import Docs.Components

@[expose] public section

open Verso.Genre.Blog (Page)

#doc (Page) "Overview" =>

crdtlib is a Lean 4 library of operation-based CRDTs. A small set of combinators builds complex CRDTs out of simpler ones, and each combinator proves that its result converges.
Anything you assemble from them is therefore a CRDT by construction: verified in Lean and executable.

:::Docs.guideCards
:::

# The building blocks

Every CRDT in the library is assembled from primitives and principal and derived combinators.
The same colors mark them throughout the documentation.

:::Shared.recipeLegend
:::

The _primitive_ CRDTs are written by hand, with a hand-written commutativity proof. The combinators each preserve commutativity:

:::Shared.combinatorGrid "principal"
:::

The _derived_ combinators are defined in terms of the principal ones, so they do not need their own proof:

:::Shared.combinatorGrid "derived"
:::

# Reading the source

Code excerpts in this documentation are taken from the library. To follow along in the repository:

:::Docs.sourceTable
:::
