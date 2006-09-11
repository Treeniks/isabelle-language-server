(*
    ID:         $Id$
    Author:     Amine Chaieb, TU Muenchen
*)

header {* Examples for generic reflection and reification *}

theory ReflectionEx
imports Reflection
begin

text{* This theory presents two methods: reify and reflection *}

text{* 
Consider an HOL type 'a, the structure of which is not recongnisable on the theory level. This is the case of bool, arithmetical terms such as int, real etc\<dots> 
In order to implement a simplification on terms of type 'a we often need its structure.
Traditionnaly such simplifications are written in ML, proofs are synthesized.
An other strategy is to declare an HOL-datatype tau and an HOL function (the interpretation) that maps elements of tau to elements of 'a. The functionality of @{text reify} is to compute a term s::tau, which is the representant of t. For this it needs equations for the interpretation.

NB: All the interpretations supported by @{text reify} must have the type @{text "'b list \<Rightarrow> tau \<Rightarrow> 'a"}.
The method @{text reify} can also be told which subterm of the current subgoal should be reified. The general call for @{text reify} is: @{text "reify eqs (t)"}, where @{text eqs} are the defining equations of the interpretation and @{text "(t)"} is an optional parameter which specifies the subterm to which reification should be applied to. If @{text "(t)"} is abscent, @{text reify} tries to reify the whole subgoal.

The method reflection uses @{text reify} and has a very similar signature: @{text "reflection corr_thm eqs (t)"}. Here again @{text eqs} and @{text "(t)"} are as described above and @{text corr_thm} is a thorem proving @{term "I vs (f t) = I vs t"}. We assume that @{text I} is the interpretation and @{text f} is some useful and executable simplification of type @{text "tau \<Rightarrow> tau"}. The method @{text reflection} applies reification and hence the theorem @{term "t = I xs s"} and hence using @{text corr_thm} derives @{term "t = I xs (f s)"}. It then uses normalization by evaluation to prove @{term "f s = s'"} which almost finishes the proof of @{term "t = t'"} where @{term "I xs s' = t'"}.
*}

text{* Example 1 : Propositional formulae and NNF.*}
text{* The type @{text fm} represents simple propositional formulae: *}

datatype fm = And fm fm | Or fm fm | Imp fm fm | Iff fm fm | NOT fm | At nat

consts Ifm :: "bool list \<Rightarrow> fm \<Rightarrow> bool"
primrec
  "Ifm vs (At n) = vs!n"
  "Ifm bs (And p q) = (Ifm bs p \<and> Ifm bs q)"
  "Ifm vs (Or p q) = (Ifm vs p \<or> Ifm vs q)"
  "Ifm vs (Imp p q) = (Ifm vs p \<longrightarrow> Ifm vs q)"
  "Ifm vs (Iff p q) = (Ifm vs p = Ifm vs q)"
  "Ifm vs (NOT p) = (\<not> (Ifm vs p))"

consts fmsize :: "fm \<Rightarrow> nat"
primrec
  "fmsize (At n) = 1"
  "fmsize (NOT p) = 1 + fmsize p"
  "fmsize (And p q) = 1 + fmsize p + fmsize q"
  "fmsize (Or p q) = 1 + fmsize p + fmsize q"
  "fmsize (Imp p q) = 2 + fmsize p + fmsize q"
  "fmsize (Iff p q) = 2 + 2* fmsize p + 2* fmsize q"



  text{* Method @{text reify} maps a bool to an fm. For this it needs the 
  semantics of fm, i.e.\ the rewrite rules in @{text Ifm.simps}. *}
lemma "Q \<longrightarrow> (D & F & ((~ D) & (~ F)))"
apply (reify Ifm.simps)
oops

  (* You can also just pick up a subterm to reify \<dots> *)
lemma "Q \<longrightarrow> (D & F & ((~ D) & (~ F)))"
apply (reify Ifm.simps ("((~ D) & (~ F))"))
oops

  text{* Let's perform NNF. This is a version that tends to generate disjunctions *}
consts nnf :: "fm \<Rightarrow> fm"
recdef nnf "measure fmsize"
  "nnf (At n) = At n"
  "nnf (And p q) = And (nnf p) (nnf q)"
  "nnf (Or p q) = Or (nnf p) (nnf q)"
  "nnf (Imp p q) = Or (nnf (NOT p)) (nnf q)"
  "nnf (Iff p q) = Or (And (nnf p) (nnf q)) (And (nnf (NOT p)) (nnf (NOT q)))"
  "nnf (NOT (And p q)) = Or (nnf (NOT p)) (nnf (NOT q))"
  "nnf (NOT (Or p q)) = And (nnf (NOT p)) (nnf (NOT q))"
  "nnf (NOT (Imp p q)) = And (nnf p) (nnf (NOT q))"
  "nnf (NOT (Iff p q)) = Or (And (nnf p) (nnf (NOT q))) (And (nnf (NOT p)) (nnf q))"
  "nnf (NOT (NOT p)) = nnf p"
  "nnf (NOT p) = NOT p"

  text{* The correctness theorem of nnf: it preserves the semantics of fm *}
lemma nnf: "Ifm vs (nnf p) = Ifm vs p"
  by (induct p rule: nnf.induct) auto

  text{* Now let's perform NNF using our @{term nnf} function defined above. First to the whole subgoal. *}
lemma "(\<not> (A = B)) \<and> (B \<longrightarrow> (A \<noteq> (B | C \<and> (B \<longrightarrow> A | D)))) \<longrightarrow> A \<or> B \<and> D"
apply (reflection nnf Ifm.simps)
oops

  text{* Now we specify on which subterm it should be applied*}
lemma "(\<not> (A = B)) \<and> (B \<longrightarrow> (A \<noteq> (B | C \<and> (B \<longrightarrow> A | D)))) \<longrightarrow> A \<or> B \<and> D"
apply (reflection nnf Ifm.simps ("(B | C \<and> (B \<longrightarrow> A | D))"))
oops


  (* Example 2 : Simple arithmetic formulae *)

  text{* The type @{text num} reflects linear expressions over natural number *}
datatype num = C nat | Add num num | Mul nat num | Var nat | CN nat nat num

text{* This is just technical to make recursive definitions easier. *}
consts num_size :: "num \<Rightarrow> nat" 
primrec 
  "num_size (C c) = 1"
  "num_size (Var n) = 1"
  "num_size (Add a b) = 1 + num_size a + num_size b"
  "num_size (Mul c a) = 1 + num_size a"
  "num_size (CN n c a) = 4 + num_size a "

  text{* The semantics of num *}
consts Inum:: "nat list \<Rightarrow> num \<Rightarrow> nat"
primrec 
  Inum_C  : "Inum vs (C i) = i"
  Inum_Var: "Inum vs (Var n) = vs!n"
  Inum_Add: "Inum vs (Add s t) = Inum vs s + Inum vs t"
  Inum_Mul: "Inum vs (Mul c t) = c * Inum vs t"
  Inum_CN : "Inum vs (CN n c t) = c*(vs!n) + Inum vs t"

  text{* Let's reify some nat expressions \<dots> *}
lemma "4 * (2*x + (y::nat)) \<noteq> 0"
  apply (reify Inum.simps ("4 * (2*x + (y::nat))"))
oops
text{* We're in a bad situation!! The term above has been recongnized as a constant, which is correct but does not correspond to our intuition of the constructor C. It should encapsulate constants, i.e. numbers, i.e. numerals.*}

  text{* So let's leave the Inum_C equation at the end and see what happens \<dots>*}
lemma "4 * (2*x + (y::nat)) \<noteq> 0"
  apply (reify Inum_Var Inum_Add Inum_Mul Inum_CN Inum_C ("4 * (2*x + (y::nat))"))
oops
text{* Better, but it still reifies @{term x} to @{term "C x"}. Note that the reification depends on the order of the equations. The problem is that the right hand side of @{thm Inum_C} matches any term of type nat, which makes things bad. We want only numerals to match\<dots> So let's specialize @{text Inum_C} with numerals.*}

lemma Inum_number: "Inum vs (C (number_of t)) = number_of t" by simp
lemmas Inum_eqs = Inum_Var Inum_Add Inum_Mul Inum_CN Inum_number

  text{* Second attempt *}
lemma "1 * (2*x + (y::nat)) \<noteq> 0"
  apply (reify Inum_eqs ("1 * (2*x + (y::nat))"))
oops
  text{* That was fine, so let's try an other one\<dots> *}

lemma "1 * (2* x + (y::nat) + 0 + 1) \<noteq> 0"
  apply (reify Inum_eqs ("1 * (2*x + (y::nat) + 0 + 1)"))
oops
  text{* Oh!! 0 is not a variable \<dots> Oh! 0 is not a number_of .. thing. The same for 1. So let's add those equations too *}

lemma Inum_01: "Inum vs (C 0) = 0" "Inum vs (C 1) = 1" "Inum vs (C(Suc n)) = Suc n"
  by simp+

lemmas Inum_eqs'= Inum_eqs Inum_01

text{* Third attempt: *}

lemma "1 * (2*x + (y::nat) + 0 + 1) \<noteq> 0"
  apply (reify Inum_eqs' ("1 * (2*x + (y::nat) + 0 + 1)"))
oops
text{* Okay, let's try reflection. Some simplifications on num follow. You can skim until the main theorem @{text linum} *}
consts lin_add :: "num \<times> num \<Rightarrow> num"
recdef lin_add "measure (\<lambda>(x,y). ((size x) + (size y)))"
  "lin_add (CN n1 c1 r1,CN n2 c2 r2) =
  (if n1=n2 then 
  (let c = c1 + c2
  in (if c=0 then lin_add(r1,r2) else CN n1 c (lin_add (r1,r2))))
  else if n1 \<le> n2 then (CN n1 c1 (lin_add (r1,CN n2 c2 r2))) 
  else (CN n2 c2 (lin_add (CN n1 c1 r1,r2))))"
  "lin_add (CN n1 c1 r1,t) = CN n1 c1 (lin_add (r1, t))"  
  "lin_add (t,CN n2 c2 r2) = CN n2 c2 (lin_add (t,r2))" 
  "lin_add (C b1, C b2) = C (b1+b2)"
  "lin_add (a,b) = Add a b"
lemma lin_add: "Inum bs (lin_add (t,s)) = Inum bs (Add t s)"
apply (induct t s rule: lin_add.induct, simp_all add: Let_def)
apply (case_tac "c1+c2 = 0",case_tac "n1 \<le> n2", simp_all)
by (case_tac "n1 = n2", simp_all add: ring_eq_simps)

consts lin_mul :: "num \<Rightarrow> nat \<Rightarrow> num"
recdef lin_mul "measure size "
  "lin_mul (C j) = (\<lambda> i. C (i*j))"
  "lin_mul (CN n c a) = (\<lambda> i. if i=0 then (C 0) else CN n (i*c) (lin_mul a i))"
  "lin_mul t = (\<lambda> i. Mul i t)"

lemma lin_mul: "Inum bs (lin_mul t i) = Inum bs (Mul i t)"
by (induct t arbitrary: i rule: lin_mul.induct) (auto simp add: ring_eq_simps)

consts linum:: "num \<Rightarrow> num"
recdef linum "measure num_size"
  "linum (C b) = C b"
  "linum (Var n) = CN n 1 (C 0)"
  "linum (Add t s) = lin_add (linum t, linum s)"
  "linum (Mul c t) = lin_mul (linum t) c"
  "linum (CN n c t) = lin_add (linum (Mul c (Var n)),linum t)"

lemma linum : "Inum vs (linum t) = Inum vs t"
by (induct t rule: linum.induct, simp_all add: lin_mul lin_add)

  text{* Now we can use linum to simplify nat terms using reflection *}
lemma "(Suc (Suc 1)) * (x + (Suc 1)*y) = 3*x + 6*y"
apply (reflection linum Inum_eqs' ("(Suc (Suc 1)) * (x + (Suc 1)*y)"))
oops

  text{* Let's lift this to formulae and see what happens *}

datatype aform = Lt num num  | Eq num num | Ge num num | NEq num num | 
  Conj aform aform | Disj aform aform | NEG aform | T | F
consts linaformsize:: "aform \<Rightarrow> nat"
recdef linaformsize "measure size"
  "linaformsize T = 1"
  "linaformsize F = 1"
  "linaformsize (Lt a b) = 1"
  "linaformsize (Ge a b) = 1"
  "linaformsize (Eq a b) = 1"
  "linaformsize (NEq a b) = 1"
  "linaformsize (NEG p) = 2 + linaformsize p"
  "linaformsize (Conj p q) = 1 + linaformsize p + linaformsize q"
  "linaformsize (Disj p q) = 1 + linaformsize p + linaformsize q"


consts aform :: "nat list => aform => bool"
primrec
  "aform vs T = True"
  "aform vs F = False"
  "aform vs (Lt a b) = (Inum vs a < Inum vs b)"
  "aform vs (Eq a b) = (Inum vs a = Inum vs b)"
  "aform vs (Ge a b) = (Inum vs a \<ge> Inum vs b)"
  "aform vs (NEq a b) = (Inum vs a \<noteq> Inum vs b)"
  "aform vs (NEG p) = (\<not> (aform vs p))"
  "aform vs (Conj p q) = (aform vs p \<and> aform vs q)"
  "aform vs (Disj p q) = (aform vs p \<or> aform vs q)"

  text{* Let's reify and do reflection. *}
lemma "(3::nat)*x + t < 0 \<and> (2 * x + y \<noteq> 17)"
apply (reify Inum_eqs' aform.simps)
oops

text{* Note that reification handles several interpretations at the same time*}
lemma "(3::nat)*x + t < 0 & x*x + t*x + 3 + 1 = z*t*4*z | x + x + 1 < 0"
apply (reflection linum Inum_eqs' aform.simps ("x + x + 1"))
oops

  text{* For reflection we now define a simple transformation on aform: NNF + linum on atoms *}
consts linaform:: "aform \<Rightarrow> aform"
recdef linaform "measure linaformsize"
  "linaform (Lt s t) = Lt (linum s) (linum t)"
  "linaform (Eq s t) = Eq (linum s) (linum t)"
  "linaform (Ge s t) = Ge (linum s) (linum t)"
  "linaform (NEq s t) = NEq (linum s) (linum t)"
  "linaform (Conj p q) = Conj (linaform p) (linaform q)"
  "linaform (Disj p q) = Disj (linaform p) (linaform q)"
  "linaform (NEG T) = F"
  "linaform (NEG F) = T"
  "linaform (NEG (Lt a b)) = Ge a b"
  "linaform (NEG (Ge a b)) = Lt a b"
  "linaform (NEG (Eq a b)) = NEq a b"
  "linaform (NEG (NEq a b)) = Eq a b"
  "linaform (NEG (NEG p)) = linaform p"
  "linaform (NEG (Conj p q)) = Disj (linaform (NEG p)) (linaform (NEG q))"
  "linaform (NEG (Disj p q)) = Conj (linaform (NEG p)) (linaform (NEG q))"
  "linaform p = p"

lemma linaform: "aform vs (linaform p) = aform vs p"
  by (induct p rule: linaform.induct, auto simp add: linum)

lemma "(((Suc(Suc (Suc 0)))*((x::nat) + (Suc (Suc 0)))) + (Suc (Suc (Suc 0))) * ((Suc(Suc (Suc 0)))*((x::nat) + (Suc (Suc 0))))< 0) \<and> (Suc 0  + Suc 0< 0)"
  apply (reflection linaform Inum_eqs' aform.simps) 
oops


text{* And finally an example for binders. Here we have an existential quantifier. Binding is trough de Bruijn indices, the index of the varibles. *}

datatype afm = LT num num | EQ num | AND afm afm | OR afm afm | E afm | A afm

consts Iafm:: "nat list \<Rightarrow> afm \<Rightarrow> bool"

primrec
  "Iafm vs (LT s t) = (Inum vs s < Inum vs t)"
  "Iafm vs (EQ t) = (Inum vs t = 0)"
  "Iafm vs (AND p q) = (Iafm vs p \<and> Iafm vs q)"
  "Iafm vs (OR p q) = (Iafm vs p \<or> Iafm vs q)"
  "Iafm vs (E p) = (\<exists>x. Iafm (x#vs) p)"
  "Iafm vs (A p) = (\<forall>x. Iafm (x#vs) p)"

lemma " \<forall>(x::nat) y. \<exists> z. z < x + 3*y \<and> x + y = 0"
apply (reify Inum_eqs' Iafm.simps)
oops



end
