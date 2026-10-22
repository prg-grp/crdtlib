import Verso.Doc.ArgParse
import Verso.Doc.Html
import VersoBlog

open Verso.Genre.Blog
open Verso.Output Html
open Verso.Doc Html
open Verso ArgParse
open Verso.Genre

namespace Shared
namespace Components

instance : Coe (Option Html) Html where
  coe
    | some x => Html.seq #[x]
    | none => Html.empty

def ValDesc.option [Monad m] [Lean.MonadError m] (x : Verso.ArgParse.ValDesc m α) : Verso.ArgParse.ValDesc m (Option α) where
  signature := CanMatch.Ident
  description := x.description ++ " or none"
  get
    | .name b => if b.getId == `none then pure none else some <$> x.get (.name b)
    | other => x.get other

instance [Monad m] [Lean.MonadError m] [x : FromArgVal α m] : FromArgVal (Option α) m where
  fromArgVal := ValDesc.option x.fromArgVal

/--
Splits an array into chunks of the given size.
-/
partial defmethod Array.chunk (array : Array α) (size : Nat) : Array (Array α) :=
  let rec go (array : Array α) (size : Nat) (result : Array (Array α)) :=
    if array.size ≤ size
      then result.push array
      else go (array.drop size) size (result.push (array.take size))
  go array size #[]

/--
Sets or updates the given attribute on the first HTML tag node.
-/
def setAttribute (attr : String) (value : String) (html : Html) : Html :=
  match html with
  | .tag name attrs children =>
    match attrs.findIdx? ((· == attr) ∘ Prod.fst) with
    | none => .tag name (attrs.push (attr, value)) children
    | some i => .tag name (attrs.set! i (attr, value)) children
  | _ => html

/--
Sets an attribute on an HTML element only if the value is defined.
-/
def setAttributeOption (attr : String) (value : Option String) (html : Html) : Html :=
  if let some value := value
    then setAttribute attr value html
    else html

/--
Converts a string into a lowercase, hyphen-separated "slug" suitable for use in URLs or IDs.
Delegates to Verso's `slugifyTitle`, which lowercases, turns spaces into hyphens, and drops
punctuation — so anchors stay clean (e.g. "One name, two things" → "one-name-two-things").
-/
def createSlug (str : String) : String :=
  Verso.Genre.Blog.slugifyTitle str

/--
Returns a string if the condition is true, otherwise returns an empty string.
-/
def when (x : Bool) (value : String) :=
  if x then value else ""

end Components
end Shared
