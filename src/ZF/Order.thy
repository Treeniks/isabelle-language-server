(*  Title: 	ZF/Order.thy
    ID:         $Id$
    Author: 	Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1994  University of Cambridge

Orders in Zermelo-Fraenkel Set Theory 
*)

Order = WF + Perm + 
consts
  part_ord        :: "[i,i]=>o"		(*Strict partial ordering*)
  linear, tot_ord :: "[i,i]=>o"		(*Strict total ordering*)
  well_ord        :: "[i,i]=>o"		(*Well-ordering*)
  ord_iso         :: "[i,i,i,i]=>i"	(*Order isomorphisms*)
  pred            :: "[i,i,i]=>i"	(*Set of predecessors*)

defs
  part_ord_def "part_ord(A,r) == irrefl(A,r) & trans[A](r)"

  linear_def   "linear(A,r) == (ALL x:A. ALL y:A. <x,y>:r | x=y | <y,x>:r)"

  tot_ord_def  "tot_ord(A,r) == part_ord(A,r) & linear(A,r)"

  well_ord_def "well_ord(A,r) == tot_ord(A,r) & wf[A](r)"

  ord_iso_def  "ord_iso(A,r,B,s) == \
\                   {f: bij(A,B). ALL x:A. ALL y:A. <x,y>:r <-> <f`x,f`y>:s}"

  pred_def     "pred(A,x,r) == {y:A. <y,x>:r}"

end
