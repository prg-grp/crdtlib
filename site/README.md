# crdtlib website

The crdtlib website, built with [Verso](https://github.com/leanprover/verso)'s blog genre.

## Building

From the repository root,

    lake run generate

writes the site to `_site/`.
Preview it locally with

    lake exe verso-serve _site

at <http://localhost:8000/>.

Pages link to each other and to their files with root-absolute paths (`/docs/catalog/`, `/static/…`).
To serve the site under a path instead of the root of a domain, set the path when generating it:

    SITE_BASE_PATH=/crdtlib/ lake run generate
    lake run generate --base-path /crdtlib/

## Deploying

`.github/workflows/site.yml` builds the site on every push to `master` and deploys it to GitHub Pages, at `https://prg-grp.github.io/crdtlib/`.

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

The block's contents must match the anchored region.
