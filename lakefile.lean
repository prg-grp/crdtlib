import Lake
open Lake DSL

package crdtlib where
  license := "Apache-2.0"
  licenseFiles := #["LICENSE"]

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.35.0"

require verso from git
  "https://github.com/leanprover/verso" @ "v4.35.0"

@[default_target]
lean_lib Crdtlib where
  globs := #[.andSubmodules `Crdtlib]

/-- Examples embedded in the website. Built (and so type-checked) by the site. -/
lean_lib Examples where
  globs := #[.submodules `Examples]

/-! ## Website

Everything for the website is in `site/`: the site map (`Site`), the landing page (`Home`), the
documentation pages (`Docs`), what both use (`Shared`), and the files they serve (`static/`). `lake run generate`
builds it into `_site/`.
-/

lean_lib Site where
  srcDir := "site"
  globs := #[.one `Site, .submodules `Home, .submodules `Docs, .andSubmodules `Shared]
  moreLeancArgs := #["-O0"]

lean_exe «crdtlib-site» where
  srcDir := "site"
  root := `Site
  supportInterpreter := true
  moreLeancArgs := #["-O0"]
  moreLinkArgs :=
    if System.Platform.isOSX then #["-Wl,-ignore_optimization_hints"] else #[]

/--
Where the website is served, normalized to start and end with `/`: `crdtlib` and `/crdtlib` both
become `/crdtlib/`, and nothing at all becomes `/`.
-/
def siteBasePath (path : String) : String :=
  let parts := (path.splitOn "/").filter (· != "")
  if parts.isEmpty then "/" else "/" ++ "/".intercalate parts ++ "/"

/--
Moves the root-absolute links and file references of a generated page under `base`:
`href="/docs/"` becomes `href="/crdtlib/docs/"`. Protocol-relative URLs (`//host/…`) are left alone.
-/
def rebasePage (base page : String) : String := Id.run do
  let mut page := page
  for attr in ["href", "src", "action"] do
    let protect := s!"{attr}=\"\u0000"
    page := page.replace s!"{attr}=\"//" protect
    page := page.replace s!"{attr}=\"/" s!"{attr}=\"{base}"
    page := page.replace protect s!"{attr}=\"//"
  return page

/--
Generates the website into `_site`. Run from the repository root.

By default, the site is served from the root of a domain. To serve it under a path, such as the
GitHub Pages project site `https://prg-grp.github.io/crdtlib/`, set `SITE_BASE_PATH=/crdtlib/` or
pass `--base-path /crdtlib/`: the generated pages' root-absolute links are then rewritten to start
with it. The GitHub Actions workflow sets it from `actions/configure-pages`.
-/
script generate (args) do
  let base? ← match args with
    | [] => IO.getEnv "SITE_BASE_PATH"
    | ["--base-path", path] => pure (some path)
    | _ =>
      IO.eprintln "Usage: lake run generate [--base-path PATH]"
      return 1
  let base := siteBasePath (base?.getD "/")

  let out : System.FilePath := "_site"
  if ← out.pathExists then
    IO.FS.removeDirAll out

  let code ← IO.Process.Child.wait
    <| ← IO.Process.spawn {cmd := "lake", args := #["exe", "crdtlib-site", "--output", out.toString]}
  if code != 0 then
    return code

  IO.FS.writeFile (out / "404.html") (← IO.FS.readFile (out / "404" / "index.html"))

  if base != "/" then
    for file in ← out.walkDir do
      if file.extension == some "html" then
        IO.FS.writeFile file (rebasePage base (← IO.FS.readFile file))
  IO.println s!"Generated {out} for {base}"

  return 0
