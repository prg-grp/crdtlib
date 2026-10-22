import VersoBlog

import Shared.Basic

open Shared Components
open Verso Output Html

/-!
Heading anchors and the "On this page" table of contents for documentation pages.
-/

namespace Docs

partial def removeWrapper : Html → String
  | .text _ s => s
  | .tag _ _ h => removeWrapper h
  | .seq hs => String.intercalate " " (hs.toList.map removeWrapper)

partial def addSlug : Html → Html
  | .text s e => .text s e
  | .tag t a h =>
    match t with
    | "h1" | "h2" | "h3" | "h4" => .tag t (a.push ("id", createSlug (removeWrapper h))) h
    | _ => .tag t a (addSlug h)
  | .seq h => .seq (h.map addSlug)

partial def collectH1 (html : Html) (linkPrefix : String := "") : Option Html :=
    let res := (collect [] html |>.reverse)
    if ¬ res.isEmpty then
      let (html, _) := compact 2 res
      Html.tag "ol" #[] #[Html.seq (html.toArray |>.map (Html.tag "li" #[]))]
    else
      none
  where
    getLevel : Html → Nat
      | "h1" => 1
      | "h2" => 2
      | "h3" => 3
      | "h4" => 4
      | _ => 0

    collect (col : List (Nat × String)) : Html → List (Nat × String)
      | .text _ _ => col
      | .tag t _ h =>
        match t with
        | "h1" | "h2" | "h3" | "h4" => (getLevel t, removeWrapper h) :: col
        | _ => collect col h
      | .seq h => h.foldl collect col

    compact (current : Nat) : List (Nat × String) → (List Html × List (Nat × String))
      | (level, str) :: xs =>
        if level = current then
          let slug := createSlug str
          let headingLink := Html.tag "a" #[("href", s!"{linkPrefix}#{slug}")] #[Html.text false str]

          let (children, remaining) := compactChildren (level + 1) xs
          let item := if children.isEmpty then headingLink else Html.seq #[headingLink, Html.tag "ol" #[] (Html.seq children.toArray)]
          let (siblings, final) := compact level remaining

          (item :: siblings, final)
        else if level < current then
          ([], (level, str) :: xs)
        else
          ([], (level, str) :: xs)
      | [] => ([], [])

    compactChildren (minLevel : Nat) : List (Nat × String) → (List Html × List (Nat × String))
      | (level, str) :: xs =>
        if level >= minLevel then
          let (item, remaining) := compact level ((level, str) :: xs)
          let (siblings, final) := compactChildren minLevel remaining
          (item.map (Html.tag "li" #[]) ++ siblings, final)
        else
          ([], (level, str) :: xs)
      | [] => ([], [])

end Docs
