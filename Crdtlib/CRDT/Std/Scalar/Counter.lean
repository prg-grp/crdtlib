import Crdtlib.CRDT.Primitive.ACFun

def counter64 : CRDT Int64 Int64 Int64 := ac_fun Int64 (· + ·)

@[export counter64_effect]
def counter64Effect (event : Int64) (state : Int64) : Int64 :=
  counter64.effect event state

@[export counter64_interpret]
def counter64Interpret (state : Int64) : Int64 :=
  counter64.interpret state


def counter32' : CRDT Int32 Int32 Int32 := ac_fun Int32 (· + ·)

@[export counter32_effect]
def counter32Effect (event : Int32) (state : Int32) : Int32 :=
  counter32'.effect event state

@[export counter32_interpret]
def counter32Interpret (state : Int32) : Int32 :=
  counter32'.interpret state
