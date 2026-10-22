<p align="center">
  <img src="assets/logo.svg" width="112" alt="crdtlib logo: a square holding three bars">
</p>

<h1 align="center">crdtlib</h1>

<p align="center">Composable, verified operation-based CRDTs in Lean 4.</p>

Conflict-free replicated data types (CRDTs) keep replicas of data convergent without coordination,
which makes them building blocks for collaborative, highly available and offline-capable software.
Adopting one CRDT is straightforward, but real applications compose them: a set of counters combines
a set CRDT with a counter CRDT. Classical CRDT theory does not guarantee that a composition of
convergent CRDTs converges, so developers have to reason about convergence again, the very burden
CRDTs were meant to remove.

crdtlib assembles operation-based CRDTs from five principal combinators: `product`, `map_state`,
`associate`, `traverse` and `map_interpretation`. Each one preserves convergence, so anything built
from them is itself a CRDT, by construction. The set is free of redundancy and subsumes previously
proposed combinators. The theory, the proofs and the implementation are one Lean 4 artifact: the
definitions you read are the code you run.

crdtlib is the library of the paper
[_Composing CRDTs Convergent by Construction_](https://doi.org/10.1145/3839478) (OOPSLA 2026).

## Use

Add the Lake package `crdtlib` to your project, and use the toolchain in `lean-toolchain`. In a
`lakefile.lean`:

```lean
require crdtlib from git "https://github.com/prg-grp/crdtlib" @ "master"
```

or in a `lakefile.toml`:

```toml
[[require]]
name = "crdtlib"
git = "https://github.com/prg-grp/crdtlib"
rev = "master"
```

Run `lake update crdtlib` to fetch it.

Then import the library, and compose a CRDT. This one, from `Examples/GettingStarted.lean`, keeps a
grow-only set of tags next to a counter:

```lean
import Crdtlib

inductive TaskOp
  | tag (label : String)
  | bump (priority : Int)

def task : CRDT TaskOp (GSet String × Int) (SetInterp String × Int) :=
  map_op (λ | .tag l => .inl l | .bump n => .inr n)
    (disjoint_product (gset String) counter)
```

There is no convergence proof to write: `task.commutative` comes with the composite.

## Build

```sh
lake build           # the library
./print-axioms.sh    # the axioms behind every combinator and CRDT
lake run generate    # the website and documentation, into _site/
```

There is no `sorry` in the library, and no axioms beyond Lean's standard `propext`,
`Classical.choice` and `Quot.sound`; `print-axioms.sh` lists them for every definition.

## From the paper to the code

Paths are relative to `Crdtlib/`.

| Paper | Lean | File |
| --- | --- | --- |
| §2 Concurrency | `Concurrent` | `CRDT/Concurrent.lean` |
| §2 CRDT, with and without timestamps | `CRDT`, `CRDTₜ` | `CRDT/Basic.lean` |
| §3 Associative–commutative functions | `ac_fun`, `counter`, `gcounter`, `join`, `union_set` | `CRDT/Primitive/ACFun.lean` |
| §3 Multi-value register | `mv_regₜ` | `CRDT/Primitive/MVReg.lean` |
| §3 Multi-value LWW register | `mv_lww` | `CRDT/Std/LWW/MVLWW.lean` |
| §3 Lamport tuple, LWW register | `Lamport`, `lww` | `CRDT/Std/LWW/LWW.lean` |
| §4.1 Product | `product`, `product3` | `Combinator/Principal/Product.lean` |
| §4.2 MapState | `map_state` | `Combinator/Principal/MapState.lean` |
| §4.3 Associate | `associate` | `Combinator/Principal/Associate.lean` |
| §4.4 Traverse | `traverse` | `Combinator/Principal/Traverse.lean` |
| §4.5 MapInterpretation | `map_interpretation` | `Combinator/Principal/MapInterpretation.lean` |
| §5.1 Map operation | `map_op` | `Combinator/Derived/MapOp.lean` |
| §5.2 Disjoint product | `disjoint_product` | `Combinator/Derived/DisjointProduct.lean` |
| §5.3 Joint product | `joint_product` | `Combinator/Derived/JointProduct.lean` |
| §5.4 Tagged union | `tagged_union`, `tagged_union_interp`, `Choice` | `Combinator/Derived/TaggedUnion.lean` |
| §6 Set operations and interpretation | `SetOp`, `SetInterp` | `CRDT/Std/Set/Basic.lean` |
| §6 Grow-only set | `GSet`, `gset` | `CRDT/Std/Set/GSet.lean` |
| §6 Two-phase set | `tpset` | `CRDT/Std/Set/TPSet.lean` |
| §6 LWW-element set | `lww_element_set` | `CRDT/Std/Set/LWWSet.lean` |
| §6 PN-set | `pnset` | `CRDT/Std/Set/PNSet.lean` |
| §6 OR-set | `orset` | `CRDT/Std/Set/ORSet.lean` |
| §6 Add-remove partial order (list) | `polist` | `CRDT/Std/List/POList.lean` |

The paper's two larger case studies, a tic-tac-toe game with forkable game trees and chat, and a
JSON tree CRDT as expressive as Automerge, are in the paper's artifact
([Zenodo](https://doi.org/10.5281/zenodo.21532005)), together with the benchmarks.

## Layout

- `Crdtlib/`: the library: the CRDT definition, primitives, combinators, and a catalog of CRDTs
- `Examples/`: examples shown in the documentation, compiled with it
- `bindings/rust/`: Rust bindings
- `site/`: the website and documentation (see `site/README.md`)
- `assets/`: the logo, icons and drawings

## Citing

```bibtex
@article{StadingDominguez2026Composing,
  title     = {Composing {CRDTs} Convergent by Construction},
  author    = {St{\"a}ding Dominguez, Alexander and Zakhour, George and
               Weisenburger, Pascal and Salvaneschi, Guido},
  journal   = {Proc. ACM Program. Lang.},
  volume    = {10},
  number    = {OOPSLA2},
  articleno = {346},
  year      = {2026},
  doi       = {10.1145/3839478}
}
```

## License

Apache License 2.0. See [`LICENSE`](LICENSE).
