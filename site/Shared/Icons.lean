import VersoBlog

open Verso.Output Html

/-!
Icons, from `assets/icons/`. They are included in the page as they are, rather than linked, so that
they draw with `currentColor` and follow the surrounding text color. The files are read when this
module is compiled: after changing one, rebuild with `lake build Shared.Icons`.
-/

namespace Shared
namespace Icons

def github : Html := .text false (include_str "../../assets/icons/github.svg")
def moon : Html := .text false (include_str "../../assets/icons/moon.svg")
def sun : Html := .text false (include_str "../../assets/icons/sun.svg")
def arrowRight : Html := .text false (include_str "../../assets/icons/arrow-right.svg")
def external : Html := .text false (include_str "../../assets/icons/external.svg")
def check : Html := .text false (include_str "../../assets/icons/check.svg")
def menu : Html := .text false (include_str "../../assets/icons/menu.svg")
def play : Html := .text false (include_str "../../assets/icons/play.svg")
def pause : Html := .text false (include_str "../../assets/icons/pause.svg")
def chevronLeft : Html := .text false (include_str "../../assets/icons/chevron-left.svg")
def chevronRight : Html := .text false (include_str "../../assets/icons/chevron-right.svg")

end Icons
end Shared
