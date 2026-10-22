# crdtlib website

The crdtlib website, built with [Verso](https://github.com/leanprover/verso)'s blog genre. It is one site: a landing page that introduces the main ideas, with a carousel of constructions, and documentation pages under `/docs/` that cover everything in detail.

```
site/
├── Site.lean     the site map and entry point
├── Home/         the landing page and the site's theme
├── Docs/         the documentation pages and their layout
├── Shared/       what both use: brand, header, footer, data, cards, layout directives
├── Shared.lean
└── static/       the stylesheets and scripts the site serves
```

It is built by the top-level Lake project (`lean_lib Site` and `lean_exe crdtlib-site` in `../lakefile.lean`) and shares its Lean toolchain.

## Building

From the repository root,

    lake run generate

writes the site to `_site/`. Preview it with

    lake exe verso-serve _site

at <http://localhost:8000/>.

Pages link to each other and to their files with root-absolute paths (`/docs/catalog/`, `/static/…`). To serve the site under a path instead of the root of a domain, set the path when generating it:

    SITE_BASE_PATH=/crdtlib/ lake run generate
    lake run generate --base-path /crdtlib/

Every root-absolute link and file reference in the generated pages then starts with `/crdtlib/`.

## Deploying

`.github/workflows/site.yml` builds the site on every push to `master` and deploys it to GitHub Pages, at `https://prg-grp.github.io/crdtlib/`. It takes the path from `actions/configure-pages`, so it follows the repository's Pages settings; to serve the site from a custom domain's root, set `SITE_BASE_PATH` to `/` in the workflow. The repository's Pages source must be set to "GitHub Actions".

## Code excerpts

Every Lean excerpt on the site is taken from the library (or from `Examples/`) and checked when the site is built, so it cannot drift from the source.

1. Mark the region in the Lean file:

       -- ANCHOR: orset
       def orset …
       -- ANCHOR_END: orset

2. Show it on a page:

       ```anchor orset (module := Crdtlib.CRDT.Std.Set.ORSet)
       def orset …
       ```

   The block's contents must match the anchored region. If the library changes, the build fails with the expected text, and the editor offers to update the block.

`Examples/GettingStarted.lean` holds the examples for the "Get started" page. It is part of the `Examples` library, which is not a default target but is built along with the site.

## The site

 * `Site.lean`: the site map, from URLs to pages.
 * `Home/Theme.lean`: the theme of every page: the `<head>`, header and footer, and the page layout. The landing page and the 404 page lay themselves out; documentation pages use `Docs.pageTemplate`.

## The landing page

 * `Home/Home.lean`: the page, in Verso markup, assembled from layout directives.
 * `Home/Showcase.lean`: the carousel's slides. Each is a construction (a tree of combinators over CRDTs) and a few operations played on it: the operation as it arrives at each node on its way to a leaf, the leaf's new state, and what combinators whose interpretation does something read as. The build computes the rest of the interpretations, and checks that each operation names an existing leaf, has one label per edge on its way there, and that the interpretations agree with what the application reads.
 * `Home/Diagram.lean`: lays out a construction as a tree and draws it as SVG.
 * `Home/Carousel.lean`: the carousel directive.
 * `Home/Hero.lean`, `Home/NotFound.lean`: the headline and the 404 page.
 * `Home/Publications.lean`: the Publications page, listing `Shared.publications`. Add a paper there to list it.
 * `static/js/showcase.js`: plays the slides. The diagrams assemble bottom-up, then each operation travels down to the leaves it updates, and the interpretation is read back up. The carousel pauses with its pause button and off screen, respects reduced motion, and without JavaScript shows every slide in its final state.
 * `static/css/home.css`, `static/css/showcase.css`: styles for the page and the carousel.

To add a slide, append to `Home.slides`.

## The documentation

 * `Docs/Pages/*.lean`: the pages. They appear in the sidebar in the order of the site map, grouped by `Docs.groupOf`.
 * `Docs/Theme.lean`: the layout of a documentation page, with the sidebar and pager; `Docs/Toc.lean` builds the list of sections of the current page.
 * `Docs/Components.lean`: directives used only by the documentation.
 * `static/css/doc.css`, `static/js/toc.js`: the documentation's stylesheet and script.

To add a page, create `Docs/Pages/Foo.lean` with a `#doc (Page) "Foo" =>` block, import it in `Site.lean`, add `"foo" Docs.Pages.Foo` under `"docs"` in the site map, and give it a group in `Docs.groupOf`.

## Shared

 * `Shared/Data.lean`: the combinators, the catalog entries with their recipes, the paper, and the paper's combinator-usage table. Unlike the code excerpts, this data is not checked against the library.
 * `Shared/Cards.lean`: recipes (nested boxes), type slots (`ω σ γ`), combinator and CRDT cards, the usage table, and the list of publications.
 * `Shared/Layout.lean`: directives for free-form pages (`band`, `split`, `col`, `steps`, `features`, `callout`, `actions`). They nest by colon count: `band` (6) > `split` (5) > `col` (4) > everything else (3).
 * `Shared/Brand.lean`: the site name, repository URL, and where the documentation lives. Rename the site here.
 * `Shared/Icons.lean`, `Shared/Tools.lean`, `Shared/Diagrams.lean`: the icons, the combinator tools and the convergence figure, read from `assets/` (see below).
 * `Shared/Tools.lean`: a tool for each combinator (a clamp for `product`, a plane for `map_state`, …), drawn as SVG on a square tile, in the color of the combinator's role. The cards, the documentation's signatures, the carousel's chips and the diagrams' combinator boxes show them.
 * `Shared/Head.lean`, `NavBar.lean`, `Footer.lean`, `Icons.lean`, `Diagrams.lean`: page chrome and the convergence figure.
 * `static/css/base.css`: the design tokens for both themes and the components every page uses, with `static/js/dark.js` and `static/js/copy.js`.

## Images

Every image is its own file in `assets/`, at the root of the repository:

 * `assets/logo.svg`, `favicon.ico`, `apple-touch-icon.png`: the logo and the browser icons. The site serves `assets/` under `/assets/`.
 * `assets/icons/`: interface icons, such as the theme toggle and the carousel's controls.
 * `assets/tools/`: the drawing for each combinator.
 * `assets/figures/`: the convergence figure.

The pages include the SVGs as they are rather than linking to them, so that the site's CSS colors them: icons follow the text color, and tools the color of the combinator's role. They are read when the Lean module that uses them is compiled, which Lake does not track: after changing one, rebuild that module, e.g. `lake build Shared.Icons`, before generating the site.

The carousel's construction diagrams are the exception. They are drawn from each slide's data by `Home/Diagram.lean`.

## Design

The site is flat and compact: sharp corners (2–4px), thin borders, little padding, and Open Sans throughout, with Fira Code for code.

Three colors run through the site, in the diagrams, recipes, cards, logo, tool drawings and figures: indigo for the five principal combinators, teal for derived combinators, and orange for primitive CRDTs. Derived combinators are also drawn with dashed outlines, and CRDTs that are themselves built from combinators, shown as a single box, with dotted ones. In the carousel, operations travel as indigo bubbles (ω), and interpretations as green ones (γ).
