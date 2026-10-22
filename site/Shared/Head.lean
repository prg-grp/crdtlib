module

public import VersoBlog
public import Shared.Brand

@[expose] public section

open Verso.Genre Blog Template
open Verso.Output Html

namespace Shared
namespace Theme

/-- Metadata for link previews. -/
structure SocialMeta where
  siteName : String
  title : String
  description : String
  type : String := "website"
  url : String

def SocialMeta.toHtml (data : SocialMeta) : Html := {{
  <meta property="og:title" content={{ data.title }}/>
  <meta property="og:description" content={{ data.description }}/>
  <meta property="og:type" content={{ data.type }}/>
  <meta property="og:url" content={{ data.url }}/>
  <meta property="og:site_name" content={{ data.siteName }}/>
  <meta name="twitter:card" content="summary"/>
  <meta name="twitter:title" content={{ data.title }}/>
  <meta name="twitter:description" content={{ data.description }}/>
}}

/--
What differs between the `<head>` of the landing page and of the documentation pages. Stylesheets
and scripts are served from `site/static/` under `/static/`, and the logo and icons from `assets/`
under `/assets/`.
-/
structure HeadConfig where
  /-- The title of the start page. Other pages are titled `{page} · {titleSuffix}`. -/
  rootTitle : String
  titleSuffix : String
  description : String
  social : SocialMeta
  /-- The section's own stylesheets, loaded after the shared ones. Paths are relative to `static/`. -/
  stylesheets : Array String
  /-- Set on the 404 page, which can be served at any path. -/
  base : Option String := none

/-- The shared stylesheets, loaded first on every page. -/
def sharedStylesheets : Array String := #["css/reset.css", "css/base.css"]

def head (cfg : HeadConfig) : TemplateM Html := do
  let title ← param (α := String) "title"
  let page ← currentPath
  let static := "/static/"

  return {{
    <head>
      {{ cfg.base.map ({{ <base href={{ · }} /> }}) |>.getD .empty }}
      <meta charset="UTF-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1"/>
      {{ if page == .root
          then {{ <title>{{ cfg.rootTitle }}</title> }}
          else {{ <title>{{ title }} s!" · {cfg.titleSuffix}"</title> }} }}
      <meta name="description" content={{ cfg.description }}/>
      <meta name="theme-color" content="#f7f6f2" media="(prefers-color-scheme: light)"/>
      <meta name="theme-color" content="#0e1117" media="(prefers-color-scheme: dark)"/>
      <link rel="icon" href="/assets/logo-mark.svg" type="image/svg+xml"/>
      <link rel="icon" href="/assets/favicon.ico" sizes="32x32"/>
      <link rel="apple-touch-icon" href="/assets/apple-touch-icon.png"/>
      {{ cfg.social.toHtml }}

      <link rel="preconnect" href="https://fonts.googleapis.com"/>
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
      <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500;600&family=Open+Sans:wght@400;500;600;700&display=swap"/>

      -- Sets the theme class before the first paint, so dark mode does not flash.
      <script src=s!"{static}js/dark.js"/>
      {{ ← builtinHeader }}
      {{ sharedStylesheets.map fun css => {{ <link rel="stylesheet" href=s!"{static}{css}"/> }} }}
      {{ cfg.stylesheets.map fun css => {{ <link rel="stylesheet" href=s!"{static}{css}"/> }} }}
    </head>
  }}

end Theme
end Shared
