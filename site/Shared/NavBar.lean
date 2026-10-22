module

public import VersoBlog
public import Shared.Brand
public import Shared.Icons

@[expose] public section

open Verso.Output Html

namespace Shared
namespace Components

/-- A link in the navigation bar. -/
structure Item where
  title : String
  url : String
  active : Bool := false
deriving Repr

def navItem (item : Item) : Html := {{
  <li>
    <a class=s!"nav-link{if item.active then " active" else ""}" href={{ item.url }}
      aria-current={{ if item.active then "page" else "false" }}>{{ item.title }}</a>
  </li>
}}

/--
The navigation bar of both sites. `siteSection` is shown next to the logo, as a link to that site's
start page: the documentation passes `("Docs", docsRoot)`.

On narrow screens the links collapse behind a menu button, which works without JavaScript (it
toggles a checkbox).
-/
def navBar (items : Array Item) (siteSection : Option (String × String) := none) : Html := {{
  <nav class="navbar" aria-label="Primary">
    <div class="container navbar-inner">
      <div class="brand-group">
        <a class="brand" href="/" aria-label=s!"{siteName} home">{{ wordmark }}</a>
        {{ siteSection.map (fun (label, url) => {{
            <a class="brand-section" href={{ url }}>{{ label }}</a>
          }}) |>.getD .empty }}
      </div>
      <input type="checkbox" id="nav-toggle" class="nav-toggle"/>
      <label for="nav-toggle" class="nav-toggle-label" aria-label="Toggle navigation">{{ Icons.menu }}</label>
      <div class="nav-menu">
        <ul class="nav-links">{{ items.map navItem }}</ul>
        <div class="nav-actions">
          <button class="icon-button change-theme" type="button" aria-label="Toggle dark mode">
            <span class="when-light">{{ Icons.moon }}</span>
            <span class="when-dark">{{ Icons.sun }}</span>
          </button>
          <a class="icon-button" href={{ repoUrl }} aria-label="Source on GitHub">{{ Icons.github }}</a>
        </div>
      </div>
    </div>
  </nav>
}}

end Components
end Shared
