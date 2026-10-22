module

public import VersoBlog
public import Shared.Directive

@[expose] public section

open Verso Genre Blog
open Verso.Output Html

/-!
Layout directives for free-form pages. They wrap ordinary Verso content, so pages stay mostly
Markdown:

```
:::::Shared.band "convergence" "Convergence" "Order stops mattering"
::::Shared.split "even"
:::Shared.col
Some text.
:::
:::Shared.col
More text.
:::
::::
:::::
```
-/

namespace Shared

/-- A full-width page section with an anchor, a small kicker line, and a heading. -/
block_component band (anchor : String) (kicker : String) (title : String) where
  toHtml _ _ _ goB contents := do
    return {{
      <section class="band" id={{ anchor }}>
        <div class="container">
          <header class="band-head">
            <p class="kicker">{{ kicker }}</p>
            <h2>{{ title }}</h2>
          </header>
          <div class="band-body">{{ ← contents.mapM goB }}</div>
        </div>
      </section>
    }}

block_directive band (anchor : String) (kicker : String) (title : String)

/--
Two columns side by side on wide screens, stacked on narrow ones. Use `col` for each column.
`layout` is `even`, or `code-right` or `code-left` to make that column wider for code.
-/
block_component split (layout : String) where
  toHtml _ _ _ goB contents := do
    let cls := if layout == "even" then "split" else s!"split {layout}"
    return {{ <div class={{ cls }}>{{ ← contents.mapM goB }}</div> }}

block_directive split (layout : String)

block_component col where
  toHtml _ _ _ goB contents := do
    return {{ <div class="split-col">{{ ← contents.mapM goB }}</div> }}

block_directive col

/-- Numbered steps: wraps an ordered list and draws the numbers as badges. `layout` is `column` or `row`. -/
block_component steps (layout : String) where
  toHtml _ _ _ goB contents := do
    return {{ <div class=s!"steps {layout}">{{ ← contents.mapM goB }}</div> }}

block_directive steps (layout : String)

/-- A bulleted list laid out as columns of short features. Start each item with a bold phrase. -/
block_component features where
  toHtml _ _ _ goB contents := do
    return {{ <div class="features">{{ ← contents.mapM goB }}</div> }}

block_directive features

/-- A subheading within a band, such as "Principal" above a group of cards. -/
block_component subheading (title : String) where
  toHtml _ _ _ _ _ := do
    return {{ <h3 class="band-subhead">{{ title }}</h3> }}

block_directive subheading (title : String)

/-- A highlighted note. -/
block_component callout (label : String) where
  toHtml _ _ _ goB contents := do
    return {{
      <aside class="callout">
        <p class="callout-label">{{ label }}</p>
        {{ ← contents.mapM goB }}
      </aside>
    }}

block_directive callout (label : String)

/-- A row of call-to-action links. Each argument is `label|url`; the first is the primary one. -/
block_component actions (links : String) where
  toHtml _ _ _ _ _ := do
    let parsed := (links.splitOn ";").filterMap fun item =>
      match item.trimAscii.copy.splitOn "|" with
      | [label, url] => some (label.trimAscii.copy, url.trimAscii.copy)
      | _ => none
    let buttons := parsed.toArray.mapIdx fun i (label, url) =>
      {{ <a class=s!"button {if i == 0 then "primary" else "secondary"}" href={{ url }}>{{ label }}</a> }}
    return {{ <div class="actions">{{ buttons }}</div> }}

block_directive actions (links : String)

end Shared
