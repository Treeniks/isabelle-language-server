(*  Title:      HOL/Arith.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1993  University of Cambridge

Arithmetic operators + - and * (for div, mod and dvd, see Divides)
*)

Arith = Nat +

instance
  nat :: {plus, minus, times, power}

(* size of a datatype value; overloaded *)
consts size :: 'a => nat

primrec "op +" nat 
  add_0    "0 + n = n"
  add_Suc  "Suc m + n = Suc(m + n)"

primrec "op -" nat 
  diff_0   "m - 0 = m"
  diff_Suc "m - Suc n = (case m - n of 0 => 0 | Suc k => k)"

syntax pred :: nat => nat
translations "pred m" => "m - 1"

primrec "op *"  nat 
  mult_0   "0 * n = 0"
  mult_Suc "Suc m * n = n + (m * n)"

end
