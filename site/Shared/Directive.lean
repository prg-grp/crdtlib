module

public import VersoBlog
public meta import VersoBlog

@[expose] public section

/-!
# Directives for block components

`block_component +directive` defines a component together with a directive that uses it, but it
declares the directive's expander as an ordinary definition, which the module system rejects: an
expander runs while documents are elaborated, so it must be `meta`.

`block_directive` declares that directive, as `meta`, for a component defined with a plain
`block_component`. Its arguments are the component's parameters, which become the directive's
positional arguments:

```
block_component band (anchor : String) (title : String) where
  toHtml _ _ _ goB contents := …

block_directive band (anchor : String) (title : String)
```

after which a page can use `:::band "id" "Title"`.
-/

namespace Shared

open Lean Elab Command
open Verso ArgParse
open Verso.Genre.Blog (argNamesTypes)

syntax (name := blockDirective) "block_directive " ident (ppSpace bracketedBinder)* : command

elab_rules : command
  | `(command| block_directive $x $args*) => do
    let argNames := args.flatMap argNamesTypes
    let dirName := mkIdentFrom x (x.getId ++ `directive)
    let argsName := mkIdentFrom x (x.getId ++ `DirectiveArgs)
    let instName := mkIdentFrom x (x.getId ++ `instFromArgs)
    let argPat : Term ← argNames.foldrM (init := ← `(Unit.unit)) fun (x, _) y => `(($x, $y))
    let argP : Term ← argNames.foldrM (init := ← ``(ArgParse.done)) fun (x, t) y =>
      ``((·, ·) <$> ArgParse.positional $(quote x.getId) (FromArgVal.fromArgVal (α := $t)) <*> $y)
    let argT ← argNames.foldrM (init := ← `(Unit)) fun (_, t) y => `($t × $y)
    elabCommand (← `(abbrev $argsName := $argT))
    elabCommand (← `(meta instance $instName:ident : FromArgs $argsName Verso.Doc.Elab.DocElabM := ⟨$argP⟩))
    let call : Term ← argNames.foldlM (init := x) fun tm (a, _) => `($tm $$(quote $a))
    elabCommand (← `(command|
      @[directive $x]
      meta def $dirName : Verso.Doc.Elab.DirectiveExpanderOf $argsName
        | $argPat, blocks => do `($call #[$$(← blocks.mapM Verso.Doc.Elab.elabBlock),*])))

end Shared
