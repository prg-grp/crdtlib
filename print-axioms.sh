#!/bin/bash
lake env lean --stdin <<'EOF'
import Crdtlib
#print axioms ac_fun
#print axioms counter
#print axioms gcounter
#print axioms join
#print axioms union_set
#print axioms mv_regₜ
#print axioms mv_lwwₜ
#print axioms lww
#print axioms product
#print axioms product3
#print axioms map_state
#print axioms associate
#print axioms traverse
#print axioms map_interpretation
#print axioms map_op
#print axioms disjoint_product
#print axioms joint_product
#print axioms tagged_unionₜ
#print axioms gset
#print axioms tpset
#print axioms lww_element_set
#print axioms pnset
#print axioms or_set
#print axioms po_list
EOF
