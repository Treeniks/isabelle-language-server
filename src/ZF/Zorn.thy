(*  Title:      ZF/Zorn.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1994  University of Cambridge

Based upon the article
    Abrial & Laffitte, 
    Towards the Mechanization of the Proofs of Some 
    Classical Theorems of Set Theory. 

Union_in_Pow is proved in ZF.ML
*)

theory Zorn = OrderArith + AC + Inductive:

constdefs
  Subset_rel :: "i=>i"
   "Subset_rel(A) == {z: A*A . EX x y. z=<x,y> & x<=y & x~=y}"

  chain      :: "i=>i"
   "chain(A)      == {F: Pow(A). ALL X:F. ALL Y:F. X<=Y | Y<=X}"

  maxchain   :: "i=>i"
   "maxchain(A)   == {c: chain(A). super(A,c)=0}"
  
  super      :: "[i,i]=>i"
   "super(A,c)    == {d: chain(A). c<=d & c~=d}"


constdefs
  increasing :: "i=>i"
    "increasing(A) == {f: Pow(A)->Pow(A). ALL x. x<=A --> x<=f`x}"

(** We could make the inductive definition conditional on next: increasing(S)
    but instead we make this a side-condition of an introduction rule.  Thus
    the induction rule lets us assume that condition!  Many inductive proofs
    are therefore unconditional.
**)
consts
  "TFin" :: "[i,i]=>i"

inductive
  domains       "TFin(S,next)" <= "Pow(S)"
  intros
    nextI:       "[| x : TFin(S,next);  next: increasing(S) |]
                  ==> next`x : TFin(S,next)"

    Pow_UnionI: "Y : Pow(TFin(S,next)) ==> Union(Y) : TFin(S,next)"

  monos         Pow_mono
  con_defs      increasing_def
  type_intros   CollectD1 [THEN apply_funtype] Union_in_Pow


(*** Section 1.  Mathematical Preamble ***)

lemma Union_lemma0: "(ALL x:C. x<=A | B<=x) ==> Union(C)<=A | B<=Union(C)"
apply blast
done

lemma Inter_lemma0: "[| c:C; ALL x:C. A<=x | x<=B |] ==> A<=Inter(C) | Inter(C)<=B"
apply blast
done


(*** Section 2.  The Transfinite Construction ***)

lemma increasingD1: "f: increasing(A) ==> f: Pow(A)->Pow(A)"
apply (unfold increasing_def)
apply (erule CollectD1)
done

lemma increasingD2: "[| f: increasing(A); x<=A |] ==> x <= f`x"
apply (unfold increasing_def)
apply (blast intro: elim:); 
done

lemmas TFin_UnionI = PowI [THEN TFin.Pow_UnionI, standard]

lemmas TFin_is_subset = TFin.dom_subset [THEN subsetD, THEN PowD, standard]


(** Structural induction on TFin(S,next) **)

lemma TFin_induct:
  "[| n: TFin(S,next);   
      !!x. [| x : TFin(S,next);  P(x);  next: increasing(S) |] ==> P(next`x);  
      !!Y. [| Y <= TFin(S,next);  ALL y:Y. P(y) |] ==> P(Union(Y))  
   |] ==> P(n)"
apply (erule TFin.induct)
apply blast+
done


(*** Section 3.  Some Properties of the Transfinite Construction ***)

lemmas increasing_trans = subset_trans [OF _ increasingD2, 
                                        OF _ _ TFin_is_subset]

(*Lemma 1 of section 3.1*)
lemma TFin_linear_lemma1:
     "[| n: TFin(S,next);  m: TFin(S,next);   
         ALL x: TFin(S,next) . x<=m --> x=m | next`x<=m |] 
      ==> n<=m | next`m<=n"
apply (erule TFin_induct)
apply (erule_tac [2] Union_lemma0) (*or just Blast_tac*)
(*downgrade subsetI from intro! to intro*)
apply (blast dest: increasing_trans)
done

(*Lemma 2 of section 3.2.  Interesting in its own right!
  Requires next: increasing(S) in the second induction step. *)
lemma TFin_linear_lemma2:
    "[| m: TFin(S,next);  next: increasing(S) |] 
     ==> ALL n: TFin(S,next) . n<=m --> n=m | next`n<=m"
apply (erule TFin_induct)
apply (rule impI [THEN ballI])
(*case split using TFin_linear_lemma1*)
apply (rule_tac n1 = "n" and m1 = "x" in TFin_linear_lemma1 [THEN disjE],
       assumption+)
apply (blast del: subsetI
	     intro: increasing_trans subsetI)
apply (blast intro: elim:); 
(*second induction step*)
apply (rule impI [THEN ballI])
apply (rule Union_lemma0 [THEN disjE])
apply (erule_tac [3] disjI2)
prefer 2 apply (blast intro: elim:); 
apply (rule ballI)
apply (drule bspec, assumption) 
apply (drule subsetD, assumption) 
apply (rule_tac n1 = "n" and m1 = "x" in TFin_linear_lemma1 [THEN disjE],
       assumption+)
apply (blast intro: elim:); 
apply (erule increasingD2 [THEN subset_trans, THEN disjI1])
apply (blast dest: TFin_is_subset)+
done

(*a more convenient form for Lemma 2*)
lemma TFin_subsetD:
     "[| n<=m;  m: TFin(S,next);  n: TFin(S,next);  next: increasing(S) |]  
      ==> n=m | next`n<=m"
by (blast dest: TFin_linear_lemma2 [rule_format]) 

(*Consequences from section 3.3 -- Property 3.2, the ordering is total*)
lemma TFin_subset_linear:
     "[| m: TFin(S,next);  n: TFin(S,next);  next: increasing(S) |]  
      ==> n<=m | m<=n"
apply (rule disjE) 
apply (rule TFin_linear_lemma1 [OF _ _TFin_linear_lemma2])
apply (assumption+, erule disjI2)
apply (blast del: subsetI 
             intro: subsetI increasingD2 [THEN subset_trans] TFin_is_subset)
done


(*Lemma 3 of section 3.3*)
lemma equal_next_upper:
     "[| n: TFin(S,next);  m: TFin(S,next);  m = next`m |] ==> n<=m"
apply (erule TFin_induct)
apply (drule TFin_subsetD)
apply (assumption+)
apply (force ); 
apply (blast)
done

(*Property 3.3 of section 3.3*)
lemma equal_next_Union: "[| m: TFin(S,next);  next: increasing(S) |]   
      ==> m = next`m <-> m = Union(TFin(S,next))"
apply (rule iffI)
apply (rule Union_upper [THEN equalityI])
apply (rule_tac [2] equal_next_upper [THEN Union_least])
apply (assumption+)
apply (erule ssubst)
apply (rule increasingD2 [THEN equalityI] , assumption)
apply (blast del: subsetI
	     intro: subsetI TFin_UnionI TFin.nextI TFin_is_subset)+
done


(*** Section 4.  Hausdorff's Theorem: every set contains a maximal chain ***)
(*** NB: We assume the partial ordering is <=, the subset relation! **)

(** Defining the "next" operation for Hausdorff's Theorem **)

lemma chain_subset_Pow: "chain(A) <= Pow(A)"
apply (unfold chain_def)
apply (rule Collect_subset)
done

lemma super_subset_chain: "super(A,c) <= chain(A)"
apply (unfold super_def)
apply (rule Collect_subset)
done

lemma maxchain_subset_chain: "maxchain(A) <= chain(A)"
apply (unfold maxchain_def)
apply (rule Collect_subset)
done

lemma choice_super: "[| ch : (PROD X:Pow(chain(S)) - {0}. X);   
         X : chain(S);  X ~: maxchain(S) |]      
      ==> ch ` super(S,X) : super(S,X)"
apply (erule apply_type)
apply (unfold super_def maxchain_def)
apply blast
done

lemma choice_not_equals:
     "[| ch : (PROD X:Pow(chain(S)) - {0}. X);       
         X : chain(S);  X ~: maxchain(S) |]      
      ==> ch ` super(S,X) ~= X"
apply (rule notI)
apply (drule choice_super)
apply assumption
apply assumption
apply (simp add: super_def)
done

(*This justifies Definition 4.4*)
lemma Hausdorff_next_exists:
     "ch: (PROD X: Pow(chain(S))-{0}. X) ==>         
      EX next: increasing(S). ALL X: Pow(S).        
                   next`X = if(X: chain(S)-maxchain(S), ch`super(S,X), X)"
apply (rule bexI)
apply (rule ballI)
apply (rule beta)
apply assumption
apply (unfold increasing_def)
apply (rule CollectI)
apply (rule lam_type)
apply (simp (no_asm_simp))
apply (blast dest: super_subset_chain [THEN subsetD] chain_subset_Pow [THEN subsetD] choice_super)
(*Now, verify that it increases*)
apply (simp (no_asm_simp) add: Pow_iff subset_refl)
apply safe
apply (drule choice_super)
apply (assumption+)
apply (unfold super_def)
apply blast
done

(*Lemma 4*)
lemma TFin_chain_lemma4:
     "[| c: TFin(S,next);                               
         ch: (PROD X: Pow(chain(S))-{0}. X);            
         next: increasing(S);                           
         ALL X: Pow(S). next`X =        
                          if(X: chain(S)-maxchain(S), ch`super(S,X), X) |] 
     ==> c: chain(S)"
apply (erule TFin_induct)
apply (simp (no_asm_simp) add: chain_subset_Pow [THEN subsetD, THEN PowD] 
            choice_super [THEN super_subset_chain [THEN subsetD]])
apply (unfold chain_def)
apply (rule CollectI , blast)
apply safe
apply (rule_tac m1 = "B" and n1 = "Ba" in TFin_subset_linear [THEN disjE])
apply fast+ (*Blast_tac's slow*)
done

lemma Hausdorff: "EX c. c : maxchain(S)"
apply (rule AC_Pi_Pow [THEN exE])
apply (rule Hausdorff_next_exists [THEN bexE])
apply assumption
apply (rename_tac ch "next")
apply (subgoal_tac "Union (TFin (S,next)) : chain (S) ")
prefer 2
 apply (blast intro!: TFin_chain_lemma4 subset_refl [THEN TFin_UnionI])
apply (rule_tac x = "Union (TFin (S,next))" in exI)
apply (rule classical)
apply (subgoal_tac "next ` Union (TFin (S,next)) = Union (TFin (S,next))")
apply (rule_tac [2] equal_next_Union [THEN iffD2, symmetric])
apply (rule_tac [2] subset_refl [THEN TFin_UnionI])
prefer 2 apply (assumption)
apply (rule_tac [2] refl)
apply (simp add: subset_refl [THEN TFin_UnionI, 
                              THEN TFin.dom_subset [THEN subsetD, THEN PowD]])
apply (erule choice_not_equals [THEN notE])
apply (assumption+)
done


(*** Section 5.  Zorn's Lemma: if all chains in S have upper bounds in S 
                               then S contains a maximal element ***)

(*Used in the proof of Zorn's Lemma*)
lemma chain_extend: 
    "[| c: chain(A);  z: A;  ALL x:c. x<=z |] ==> cons(z,c) : chain(A)"
apply (unfold chain_def)
apply blast
done

lemma Zorn: "ALL c: chain(S). Union(c) : S ==> EX y:S. ALL z:S. y<=z --> y=z"
apply (rule Hausdorff [THEN exE])
apply (simp add: maxchain_def)
apply (rename_tac c)
apply (rule_tac x = "Union (c)" in bexI)
prefer 2 apply (blast)
apply safe
apply (rename_tac z)
apply (rule classical)
apply (subgoal_tac "cons (z,c) : super (S,c) ")
apply (blast elim: equalityE)
apply (unfold super_def)
apply safe
apply (fast elim: chain_extend)
apply (fast elim: equalityE)
done


(*** Section 6.  Zermelo's Theorem: every set can be well-ordered ***)

(*Lemma 5*)
lemma TFin_well_lemma5:
     "[| n: TFin(S,next);  Z <= TFin(S,next);  z:Z;  ~ Inter(Z) : Z |]   
      ==> ALL m:Z. n<=m"
apply (erule TFin_induct)
prefer 2 apply (blast) (*second induction step is easy*)
apply (rule ballI)
apply (rule bspec [THEN TFin_subsetD, THEN disjE])
apply (auto ); 
apply (subgoal_tac "m = Inter (Z) ")
apply blast+
done

(*Well-ordering of TFin(S,next)*)
lemma well_ord_TFin_lemma: "[| Z <= TFin(S,next);  z:Z |] ==> Inter(Z) : Z"
apply (rule classical)
apply (subgoal_tac "Z = {Union (TFin (S,next))}")
apply (simp (no_asm_simp) add: Inter_singleton)
apply (erule equal_singleton)
apply (rule Union_upper [THEN equalityI])
apply (rule_tac [2] subset_refl [THEN TFin_UnionI, THEN TFin_well_lemma5, THEN bspec])
apply (blast intro: elim:)+
done

(*This theorem just packages the previous result*)
lemma well_ord_TFin:
     "next: increasing(S) ==> well_ord(TFin(S,next), Subset_rel(TFin(S,next)))"
apply (rule well_ordI)
apply (unfold Subset_rel_def linear_def)
(*Prove the well-foundedness goal*)
apply (rule wf_onI)
apply (frule well_ord_TFin_lemma , assumption)
apply (drule_tac x = "Inter (Z) " in bspec , assumption)
apply blast
(*Now prove the linearity goal*)
apply (intro ballI)
apply (case_tac "x=y")
 apply (blast)
(*The x~=y case remains*)
apply (rule_tac n1=x and m1=y in TFin_subset_linear [THEN disjE],
       assumption+)
apply (blast intro: elim:)+
done

(** Defining the "next" operation for Zermelo's Theorem **)

lemma choice_Diff:
     "[| ch \<in> (\<Pi>X \<in> Pow(S) - {0}. X);  X \<subseteq> S;  X\<noteq>S |] ==> ch ` (S-X) \<in> S-X"
apply (erule apply_type)
apply (blast elim!: equalityE)
done

(*This justifies Definition 6.1*)
lemma Zermelo_next_exists:
     "ch: (PROD X: Pow(S)-{0}. X) ==>                
           EX next: increasing(S). ALL X: Pow(S).        
                      next`X = if(X=S, S, cons(ch`(S-X), X))"
apply (rule bexI)
apply (rule ballI)
apply (rule beta)
apply assumption
apply (unfold increasing_def)
apply (rule CollectI)
apply (rule lam_type)
(*Type checking is surprisingly hard!*)
apply (simp (no_asm_simp) add: Pow_iff cons_subset_iff subset_refl)
apply (blast intro!: choice_Diff [THEN DiffD1])
(*Verify that it increases*)
apply (intro allI impI) 
apply (simp add: Pow_iff subset_consI subset_refl)
done


(*The construction of the injection*)
lemma choice_imp_injection:
     "[| ch: (PROD X: Pow(S)-{0}. X);                  
         next: increasing(S);                          
         ALL X: Pow(S). next`X = if(X=S, S, cons(ch`(S-X), X)) |]  
      ==> (lam x:S. Union({y: TFin(S,next). x~: y}))        
               : inj(S, TFin(S,next) - {S})"
apply (rule_tac d = "%y. ch` (S-y) " in lam_injective)
apply (rule DiffI)
apply (rule Collect_subset [THEN TFin_UnionI])
apply (blast intro!: Collect_subset [THEN TFin_UnionI] elim: equalityE)
apply (subgoal_tac "x ~: Union ({y: TFin (S,next) . x~: y}) ")
prefer 2 apply (blast elim: equalityE)
apply (subgoal_tac "Union ({y: TFin (S,next) . x~: y}) ~= S")
prefer 2 apply (blast elim: equalityE)
(*For proving x : next`Union(...)
  Abrial & Laffitte's justification appears to be faulty.*)
apply (subgoal_tac "~ next ` Union ({y: TFin (S,next) . x~: y}) <= Union ({y: TFin (S,next) . x~: y}) ")
prefer 2
apply (simp del: Union_iff 
            add: Collect_subset [THEN TFin_UnionI, THEN TFin_is_subset] 
            Pow_iff cons_subset_iff subset_refl choice_Diff [THEN DiffD2])
apply (subgoal_tac "x : next ` Union ({y: TFin (S,next) . x~: y}) ")
prefer 2
apply (blast intro!: Collect_subset [THEN TFin_UnionI] TFin.nextI)
(*End of the lemmas!*)
apply (simp add: Collect_subset [THEN TFin_UnionI, THEN TFin_is_subset])
done

(*The wellordering theorem*)
lemma AC_well_ord: "EX r. well_ord(S,r)"
apply (rule AC_Pi_Pow [THEN exE])
apply (rule Zermelo_next_exists [THEN bexE])
apply assumption
apply (rule exI)
apply (rule well_ord_rvimage)
apply (erule_tac [2] well_ord_TFin)
apply (rule choice_imp_injection [THEN inj_weaken_type])
apply (blast intro: elim:)+
done
  
end
