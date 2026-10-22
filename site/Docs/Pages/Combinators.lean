module

public import VersoBlog
public import Shared.Cards
public import Shared.Layout

@[expose] public section

open Verso.Genre.Blog (Page)
open Verso.Code.External

set_option verso.exampleProject "."

#doc (Page) "Combinators" =>

A combinator takes CRDTs and returns a new one, together with the proof that the new one's effects commute. crdtlib has five _principal_ combinators. The derived combinators below, and every CRDT in the [catalog](/docs/catalog/), are built from them and two families of primitive CRDTs.

Each section shows how a combinator changes the three type parameters: operations `ω`, state `σ`, and interpreted state `γ`. Highlighted slots are the ones it changes.

The code uses the timestamp-free `CRDT`. Each principal combinator also exists for `CRDTₜ`, with a `ₜ` suffix, such as `productₜ`.

# Principal combinators

## Product

:::Shared.combinatorSignature "Product"
:::

This combinator composes two CRDTs such that a single operation is applied to both CRDTs. The combinator takes two CRDTs `c₁` and `c₂` such that the operation type `ω` for `c₁.effect` and `c₂.effect` is the same. The derived CRDT accepts the same operation type `ω` but maintains a state consisting of a tuple `σ₁ × σ₂`. The derived `effect` applies operations `ω` simultaneously to both substates.

```anchor product (module := Crdtlib.Combinator.Principal.Product)
def product {ω σ₁ γ₁ σ₂ γ₂ : Type*} (c₁ : CRDT ω σ₁ γ₁) (c₂ : CRDT ω σ₂ γ₂) :
    CRDT ω (σ₁ × σ₂) (γ₁ × γ₂) where
  effect e s := ⟨c₁.effect e s.1, c₂.effect e s.2⟩
  interpret s := ⟨c₁.interpret s.1, c₂.interpret s.2⟩
  commutative e₁ e₂ := by
    funext s
    simp only [Function.comp_apply, Prod.mk.injEq]
    constructor
    . exact congrFun (c₁.commutative e₁ e₂) (s.1)
    . exact congrFun (c₂.commutative e₁ e₂) (s.2)
```

For example, `productₜ (gsetₜ String) (mv_lwwₜ String)` keeps a set of strings together with the most recently inserted one.

## MapState

:::Shared.combinatorSignature "MapState"
:::

The _map state_ combinator transforms the state of a CRDT, provided that the transformation admits a left inverse. The transformation is given by a function `f` together with a left inverse `f'`.

```anchor map_state (module := Crdtlib.Combinator.Principal.MapState)
def map_state {σ₁ σ₂ ω γ} (f : σ₁ → σ₂) (f' : σ₂ → σ₁) (i : f' ∘ f = id := by funext; simp) (c : CRDT ω σ₁ γ) :
    CRDT ω σ₂ γ where
  effect e := f ∘ (c.effect e) ∘ f'
  interpret := c.interpret ∘ f'
```

A typical use is flattening the nested tuples that other combinators produce, such as turning `(σ₁ × σ₂) × σ₃` into `σ₁ × (σ₂ × σ₃)`. The [tagged union](#taggedunion) of three CRDTs does exactly this.

## Associate

:::Shared.combinatorSignature "Associate"
:::

The associate combinator constructs CRDTs that are maps. The keys of the map are immutable values and the values are CRDTs. The `associate` combinator is well-suited for defining trees in the form of path-to-node associations.

```anchor associate (module := Crdtlib.Combinator.Principal.Associate)
def associate (κ : Type*) [DecidableEq κ] [Hashable κ] [DecidableEq σ] [Zero σ] (c : CRDT ω σ γ) :
    CRDT (κ × ω) (Associate κ σ) (AssociateInterp κ γ) where
  effect e s :=
    s.alter e.fst (λ x ↦
      some $ c.effect e.2 (x.getD 0)
    )
  interpret s := {
    map k := c.interpret (s.getD k 0)
    toList := s.map (λ _ ↦ c.interpret) |> Std.ExtHashMap.toListSorted
  }
```

The interpretation exposes two functions: `toList` lists the keys, and `map` returns the state at a key or `0` if is not set.

## Traverse

:::Shared.combinatorSignature "Traverse"
:::

The _traverse_ combinator makes it possible to apply multiple operations based on a single operation.

```anchor traverse (module := Crdtlib.Combinator.Principal.Traverse)
def traverse (f : ω₂ → List ω₁) (c : CRDT ω₁ σ γ) : CRDT ω₂ σ γ where
    effect e := (f e).foldr c.effect
    interpret := c.interpret
    commutative e₁ e₂ := by
      ext _
      exact foldr_comm c.effect c.commutative _ _ _
```

The list CRDT uses it to turn one insertion between `prev` and `next` into two edges:

```anchor po_edges (module := Crdtlib.CRDT.Std.List.POList)
def edges : CRDT (σ × σ) (Associate σ (GSet σ)) (AssociateInterp σ (SetInterp σ)) :=
  associate σ (gset σ)

def po_edges : CRDT (σ × σ × σ) (Associate σ (GSet σ)) (AssociateInterp σ (SetInterp σ)) :=
  traverse (λ ⟨prev, elem, next⟩ ↦ [⟨prev, elem⟩, ⟨elem, next⟩]) (edges σ)
```

## MapInterpretation

:::Shared.combinatorSignature "MapInterpretation"
:::

This combinator transforms a CRDT's interpretation. The derived `interpret` delegates to the original `c.interpret` and uses `f` to transform the value from `γ₁` to `γ₂`. The `effect` function remains the same.

```anchor map_interpretation (module := Crdtlib.Combinator.Principal.MapInterpretation)
def map_interpretation (f : γ₁ → γ₂) (c : CRDT ω σ γ₁) : CRDT ω σ γ₂ where
  effect := c.effect
  interpret := f ∘ c.interpret
  commutative e₁ e₂ := by
    ext s
    simp
    exact congrFun (c.commutative e₁ e₂) s
```

This is where conflict resolution often lives. The [MV-LWW register](/docs/catalog/#mvlww-register) keeps all concurrent writes, like a multi-value register, and only picks a winner when it is read.

# Derived combinators

These are defined in terms of the principal combinators. They need no proofs of their own: their `commutative` fields come from the principal combinators they use.

## MapOp

:::Shared.combinatorSignature "MapOp"
:::

The `map_op` combinator adapts the operation type of a CRDT by applying a pure function `f : ω₂ → ω₁` to every incoming operation, translating it into exactly one operation of the underlying type. It is a specialization of [`traverse`](/docs/combinators/#traverse) in which the list-valued function is always `List.singleton ∘ f`: the list produced by `traverse` is guaranteed to be a singleton, so no operation is ever skipped or duplicated – in contrast to `traverse`'s general case, which allows fanout or filtering.

```anchor map_op (module := Crdtlib.Combinator.Derived.MapOp)
def map_op (f : ω₂ → ω₁) (c : CRDT ω₁ σ γ) : CRDT ω₂ σ γ :=
  traverse (List.singleton ∘ f) c
```

## DisjointProduct

:::Shared.combinatorSignature "DisjointProduct"
:::

The disjoint product combines two CRDTs into a product where each component is updated _independently_ via its own operation type – in contrast to the [`product`](/docs/combinators/#product) combinator, where both components share the same operation type and every operation is applied to both.

```anchor disjoint_product (module := Crdtlib.Combinator.Derived.DisjointProduct)
def disjoint_productₜ [PartialOrder τ] (c₁ : CRDTₜ τ ω₁ σ₁ γ₁) (c₂ : CRDTₜ τ ω₂ σ₂ γ₂) :
    CRDTₜ τ (ω₁ ⊕ ω₂) (σ₁ × σ₂) (γ₁ × γ₂) :=
  productₜ (traverseₜ (Option.toList ∘ Sum.getLeft?) c₁) (traverseₜ (Option.toList ∘ Sum.getRight?) c₂)
```

## JointProduct

:::Shared.combinatorSignature "JointProduct"
:::

The joint product, like the [disjoint product](/docs/combinators/#disjointproduct), combines two CRDTs with distinct operation types. The key distinction is that the composed operation type is a product `ω₁ × ω₂` rather than a tagged union `ω₁ ⊕ ω₂`: every operation carries one sub-operation for each component CRDT, and both are always applied _jointly_ in a single step – in contrast to the disjoint product where each incoming operation targets _either_ `c₁.effect` or `c₂.effect`.

```anchor joint_product (module := Crdtlib.Combinator.Derived.JointProduct)
def joint_product (c₁ : CRDT ω₁ σ₁ γ₁) (c₂ : CRDT ω₂ σ₂ γ₂) :
    CRDT (ω₁ × ω₂) (σ₁ × σ₂) (γ₁ × γ₂) :=
  product (map_op (·.1) c₁) (map_op (·.2) c₂)
```

## TaggedUnion

:::Shared.combinatorSignature "TaggedUnion"
:::

The tagged union combinator, like the [disjoint product](/docs/combinators/#disjointproduct) before, is a fundamental building block for encoding algebraic data types as CRDTs.

```anchor tagged_union (module := Crdtlib.Combinator.Derived.TaggedUnion)
def tagged_union_interp : (γ₁ × γ₂) × Choice → γ₁ ⊕ γ₂
  | ⟨⟨s₁, _⟩, Choice.left⟩ => Sum.inl s₁
  | ⟨⟨_, s₂⟩, Choice.right⟩ => Sum.inr s₂

def tagged_unionₜ [PartialOrder τ] [DecidableLT τ] [DecidableEq τ] (c₁ : CRDTₜ τ ω₁ σ₁ γ₁) (c₂ : CRDTₜ τ ω₂ σ₂ γ₂) :
    CRDTₜ τ ((ω₁ ⊕ ω₂) ⊕ Choice) ((σ₁ × σ₂) × (Finset (Event τ Choice))) (γ₁ ⊕ γ₂) :=
  map_interpretationₜ tagged_union_interp (disjoint_productₜ (disjoint_productₜ c₁ c₂) (mv_lwwₜ Choice))
```
