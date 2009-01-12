(*  Title:      HOL/Polynomial.thy
    Author:     Brian Huffman
                Based on an earlier development by Clemens Ballarin
*)

header {* Univariate Polynomials *}

theory Polynomial
imports Plain SetInterval
begin

subsection {* Definition of type @{text poly} *}

typedef (Poly) 'a poly = "{f::nat \<Rightarrow> 'a::zero. \<exists>n. \<forall>i>n. f i = 0}"
  morphisms coeff Abs_poly
  by auto

lemma expand_poly_eq: "p = q \<longleftrightarrow> (\<forall>n. coeff p n = coeff q n)"
by (simp add: coeff_inject [symmetric] expand_fun_eq)

lemma poly_ext: "(\<And>n. coeff p n = coeff q n) \<Longrightarrow> p = q"
by (simp add: expand_poly_eq)


subsection {* Degree of a polynomial *}

definition
  degree :: "'a::zero poly \<Rightarrow> nat" where
  "degree p = (LEAST n. \<forall>i>n. coeff p i = 0)"

lemma coeff_eq_0: "degree p < n \<Longrightarrow> coeff p n = 0"
proof -
  have "coeff p \<in> Poly"
    by (rule coeff)
  hence "\<exists>n. \<forall>i>n. coeff p i = 0"
    unfolding Poly_def by simp
  hence "\<forall>i>degree p. coeff p i = 0"
    unfolding degree_def by (rule LeastI_ex)
  moreover assume "degree p < n"
  ultimately show ?thesis by simp
qed

lemma le_degree: "coeff p n \<noteq> 0 \<Longrightarrow> n \<le> degree p"
  by (erule contrapos_np, rule coeff_eq_0, simp)

lemma degree_le: "\<forall>i>n. coeff p i = 0 \<Longrightarrow> degree p \<le> n"
  unfolding degree_def by (erule Least_le)

lemma less_degree_imp: "n < degree p \<Longrightarrow> \<exists>i>n. coeff p i \<noteq> 0"
  unfolding degree_def by (drule not_less_Least, simp)


subsection {* The zero polynomial *}

instantiation poly :: (zero) zero
begin

definition
  zero_poly_def: "0 = Abs_poly (\<lambda>n. 0)"

instance ..
end

lemma coeff_0 [simp]: "coeff 0 n = 0"
  unfolding zero_poly_def
  by (simp add: Abs_poly_inverse Poly_def)

lemma degree_0 [simp]: "degree 0 = 0"
  by (rule order_antisym [OF degree_le le0]) simp

lemma leading_coeff_neq_0:
  assumes "p \<noteq> 0" shows "coeff p (degree p) \<noteq> 0"
proof (cases "degree p")
  case 0
  from `p \<noteq> 0` have "\<exists>n. coeff p n \<noteq> 0"
    by (simp add: expand_poly_eq)
  then obtain n where "coeff p n \<noteq> 0" ..
  hence "n \<le> degree p" by (rule le_degree)
  with `coeff p n \<noteq> 0` and `degree p = 0`
  show "coeff p (degree p) \<noteq> 0" by simp
next
  case (Suc n)
  from `degree p = Suc n` have "n < degree p" by simp
  hence "\<exists>i>n. coeff p i \<noteq> 0" by (rule less_degree_imp)
  then obtain i where "n < i" and "coeff p i \<noteq> 0" by fast
  from `degree p = Suc n` and `n < i` have "degree p \<le> i" by simp
  also from `coeff p i \<noteq> 0` have "i \<le> degree p" by (rule le_degree)
  finally have "degree p = i" .
  with `coeff p i \<noteq> 0` show "coeff p (degree p) \<noteq> 0" by simp
qed

lemma leading_coeff_0_iff [simp]: "coeff p (degree p) = 0 \<longleftrightarrow> p = 0"
  by (cases "p = 0", simp, simp add: leading_coeff_neq_0)


subsection {* List-style constructor for polynomials *}

definition
  pCons :: "'a::zero \<Rightarrow> 'a poly \<Rightarrow> 'a poly"
where
  [code del]: "pCons a p = Abs_poly (nat_case a (coeff p))"

lemma Poly_nat_case: "f \<in> Poly \<Longrightarrow> nat_case a f \<in> Poly"
  unfolding Poly_def by (auto split: nat.split)

lemma coeff_pCons:
  "coeff (pCons a p) = nat_case a (coeff p)"
  unfolding pCons_def
  by (simp add: Abs_poly_inverse Poly_nat_case coeff)

lemma coeff_pCons_0 [simp]: "coeff (pCons a p) 0 = a"
  by (simp add: coeff_pCons)

lemma coeff_pCons_Suc [simp]: "coeff (pCons a p) (Suc n) = coeff p n"
  by (simp add: coeff_pCons)

lemma degree_pCons_le: "degree (pCons a p) \<le> Suc (degree p)"
by (rule degree_le, simp add: coeff_eq_0 coeff_pCons split: nat.split)

lemma degree_pCons_eq:
  "p \<noteq> 0 \<Longrightarrow> degree (pCons a p) = Suc (degree p)"
apply (rule order_antisym [OF degree_pCons_le])
apply (rule le_degree, simp)
done

lemma degree_pCons_0: "degree (pCons a 0) = 0"
apply (rule order_antisym [OF _ le0])
apply (rule degree_le, simp add: coeff_pCons split: nat.split)
done

lemma degree_pCons_eq_if:
  "degree (pCons a p) = (if p = 0 then 0 else Suc (degree p))"
apply (cases "p = 0", simp_all)
apply (rule order_antisym [OF _ le0])
apply (rule degree_le, simp add: coeff_pCons split: nat.split)
apply (rule order_antisym [OF degree_pCons_le])
apply (rule le_degree, simp)
done

lemma pCons_0_0 [simp]: "pCons 0 0 = 0"
by (rule poly_ext, simp add: coeff_pCons split: nat.split)

lemma pCons_eq_iff [simp]:
  "pCons a p = pCons b q \<longleftrightarrow> a = b \<and> p = q"
proof (safe)
  assume "pCons a p = pCons b q"
  then have "coeff (pCons a p) 0 = coeff (pCons b q) 0" by simp
  then show "a = b" by simp
next
  assume "pCons a p = pCons b q"
  then have "\<forall>n. coeff (pCons a p) (Suc n) =
                 coeff (pCons b q) (Suc n)" by simp
  then show "p = q" by (simp add: expand_poly_eq)
qed

lemma pCons_eq_0_iff [simp]: "pCons a p = 0 \<longleftrightarrow> a = 0 \<and> p = 0"
  using pCons_eq_iff [of a p 0 0] by simp

lemma Poly_Suc: "f \<in> Poly \<Longrightarrow> (\<lambda>n. f (Suc n)) \<in> Poly"
  unfolding Poly_def
  by (clarify, rule_tac x=n in exI, simp)

lemma pCons_cases [cases type: poly]:
  obtains (pCons) a q where "p = pCons a q"
proof
  show "p = pCons (coeff p 0) (Abs_poly (\<lambda>n. coeff p (Suc n)))"
    by (rule poly_ext)
       (simp add: Abs_poly_inverse Poly_Suc coeff coeff_pCons
             split: nat.split)
qed

lemma pCons_induct [case_names 0 pCons, induct type: poly]:
  assumes zero: "P 0"
  assumes pCons: "\<And>a p. P p \<Longrightarrow> P (pCons a p)"
  shows "P p"
proof (induct p rule: measure_induct_rule [where f=degree])
  case (less p)
  obtain a q where "p = pCons a q" by (rule pCons_cases)
  have "P q"
  proof (cases "q = 0")
    case True
    then show "P q" by (simp add: zero)
  next
    case False
    then have "degree (pCons a q) = Suc (degree q)"
      by (rule degree_pCons_eq)
    then have "degree q < degree p"
      using `p = pCons a q` by simp
    then show "P q"
      by (rule less.hyps)
  qed
  then have "P (pCons a q)"
    by (rule pCons)
  then show ?case
    using `p = pCons a q` by simp
qed


subsection {* Recursion combinator for polynomials *}

function
  poly_rec :: "'b \<Rightarrow> ('a::zero \<Rightarrow> 'a poly \<Rightarrow> 'b \<Rightarrow> 'b) \<Rightarrow> 'a poly \<Rightarrow> 'b"
where
  poly_rec_pCons_eq_if [simp del]:
    "poly_rec z f (pCons a p) = f a p (if p = 0 then z else poly_rec z f p)"
by (case_tac x, rename_tac q, case_tac q, auto)

termination poly_rec
by (relation "measure (degree \<circ> snd \<circ> snd)", simp)
   (simp add: degree_pCons_eq)

lemma poly_rec_0:
  "f 0 0 z = z \<Longrightarrow> poly_rec z f 0 = z"
  using poly_rec_pCons_eq_if [of z f 0 0] by simp

lemma poly_rec_pCons:
  "f 0 0 z = z \<Longrightarrow> poly_rec z f (pCons a p) = f a p (poly_rec z f p)"
  by (simp add: poly_rec_pCons_eq_if poly_rec_0)


subsection {* Monomials *}

definition
  monom :: "'a \<Rightarrow> nat \<Rightarrow> 'a::zero poly" where
  "monom a m = Abs_poly (\<lambda>n. if m = n then a else 0)"

lemma coeff_monom [simp]: "coeff (monom a m) n = (if m=n then a else 0)"
  unfolding monom_def
  by (subst Abs_poly_inverse, auto simp add: Poly_def)

lemma monom_0: "monom a 0 = pCons a 0"
  by (rule poly_ext, simp add: coeff_pCons split: nat.split)

lemma monom_Suc: "monom a (Suc n) = pCons 0 (monom a n)"
  by (rule poly_ext, simp add: coeff_pCons split: nat.split)

lemma monom_eq_0 [simp]: "monom 0 n = 0"
  by (rule poly_ext) simp

lemma monom_eq_0_iff [simp]: "monom a n = 0 \<longleftrightarrow> a = 0"
  by (simp add: expand_poly_eq)

lemma monom_eq_iff [simp]: "monom a n = monom b n \<longleftrightarrow> a = b"
  by (simp add: expand_poly_eq)

lemma degree_monom_le: "degree (monom a n) \<le> n"
  by (rule degree_le, simp)

lemma degree_monom_eq: "a \<noteq> 0 \<Longrightarrow> degree (monom a n) = n"
  apply (rule order_antisym [OF degree_monom_le])
  apply (rule le_degree, simp)
  done


subsection {* Addition and subtraction *}

instantiation poly :: (comm_monoid_add) comm_monoid_add
begin

definition
  plus_poly_def [code del]:
    "p + q = Abs_poly (\<lambda>n. coeff p n + coeff q n)"

lemma Poly_add:
  fixes f g :: "nat \<Rightarrow> 'a"
  shows "\<lbrakk>f \<in> Poly; g \<in> Poly\<rbrakk> \<Longrightarrow> (\<lambda>n. f n + g n) \<in> Poly"
  unfolding Poly_def
  apply (clarify, rename_tac m n)
  apply (rule_tac x="max m n" in exI, simp)
  done

lemma coeff_add [simp]:
  "coeff (p + q) n = coeff p n + coeff q n"
  unfolding plus_poly_def
  by (simp add: Abs_poly_inverse coeff Poly_add)

instance proof
  fix p q r :: "'a poly"
  show "(p + q) + r = p + (q + r)"
    by (simp add: expand_poly_eq add_assoc)
  show "p + q = q + p"
    by (simp add: expand_poly_eq add_commute)
  show "0 + p = p"
    by (simp add: expand_poly_eq)
qed

end

instantiation poly :: (ab_group_add) ab_group_add
begin

definition
  uminus_poly_def [code del]:
    "- p = Abs_poly (\<lambda>n. - coeff p n)"

definition
  minus_poly_def [code del]:
    "p - q = Abs_poly (\<lambda>n. coeff p n - coeff q n)"

lemma Poly_minus:
  fixes f :: "nat \<Rightarrow> 'a"
  shows "f \<in> Poly \<Longrightarrow> (\<lambda>n. - f n) \<in> Poly"
  unfolding Poly_def by simp

lemma Poly_diff:
  fixes f g :: "nat \<Rightarrow> 'a"
  shows "\<lbrakk>f \<in> Poly; g \<in> Poly\<rbrakk> \<Longrightarrow> (\<lambda>n. f n - g n) \<in> Poly"
  unfolding diff_minus by (simp add: Poly_add Poly_minus)

lemma coeff_minus [simp]: "coeff (- p) n = - coeff p n"
  unfolding uminus_poly_def
  by (simp add: Abs_poly_inverse coeff Poly_minus)

lemma coeff_diff [simp]:
  "coeff (p - q) n = coeff p n - coeff q n"
  unfolding minus_poly_def
  by (simp add: Abs_poly_inverse coeff Poly_diff)

instance proof
  fix p q :: "'a poly"
  show "- p + p = 0"
    by (simp add: expand_poly_eq)
  show "p - q = p + - q"
    by (simp add: expand_poly_eq diff_minus)
qed

end

lemma add_pCons [simp]:
  "pCons a p + pCons b q = pCons (a + b) (p + q)"
  by (rule poly_ext, simp add: coeff_pCons split: nat.split)

lemma minus_pCons [simp]:
  "- pCons a p = pCons (- a) (- p)"
  by (rule poly_ext, simp add: coeff_pCons split: nat.split)

lemma diff_pCons [simp]:
  "pCons a p - pCons b q = pCons (a - b) (p - q)"
  by (rule poly_ext, simp add: coeff_pCons split: nat.split)

lemma degree_add_le: "degree (p + q) \<le> max (degree p) (degree q)"
  by (rule degree_le, auto simp add: coeff_eq_0)

lemma degree_add_less:
  "\<lbrakk>degree p < n; degree q < n\<rbrakk> \<Longrightarrow> degree (p + q) < n"
  by (auto intro: le_less_trans degree_add_le)

lemma degree_add_eq_right:
  "degree p < degree q \<Longrightarrow> degree (p + q) = degree q"
  apply (cases "q = 0", simp)
  apply (rule order_antisym)
  apply (rule ord_le_eq_trans [OF degree_add_le])
  apply simp
  apply (rule le_degree)
  apply (simp add: coeff_eq_0)
  done

lemma degree_add_eq_left:
  "degree q < degree p \<Longrightarrow> degree (p + q) = degree p"
  using degree_add_eq_right [of q p]
  by (simp add: add_commute)

lemma degree_minus [simp]: "degree (- p) = degree p"
  unfolding degree_def by simp

lemma degree_diff_le: "degree (p - q) \<le> max (degree p) (degree q)"
  using degree_add_le [where p=p and q="-q"]
  by (simp add: diff_minus)

lemma degree_diff_less:
  "\<lbrakk>degree p < n; degree q < n\<rbrakk> \<Longrightarrow> degree (p - q) < n"
  by (auto intro: le_less_trans degree_diff_le)

lemma add_monom: "monom a n + monom b n = monom (a + b) n"
  by (rule poly_ext) simp

lemma diff_monom: "monom a n - monom b n = monom (a - b) n"
  by (rule poly_ext) simp

lemma minus_monom: "- monom a n = monom (-a) n"
  by (rule poly_ext) simp

lemma coeff_setsum: "coeff (\<Sum>x\<in>A. p x) i = (\<Sum>x\<in>A. coeff (p x) i)"
  by (cases "finite A", induct set: finite, simp_all)

lemma monom_setsum: "monom (\<Sum>x\<in>A. a x) n = (\<Sum>x\<in>A. monom (a x) n)"
  by (rule poly_ext) (simp add: coeff_setsum)


subsection {* Multiplication by a constant *}

definition
  smult :: "'a::comm_semiring_0 \<Rightarrow> 'a poly \<Rightarrow> 'a poly" where
  "smult a p = Abs_poly (\<lambda>n. a * coeff p n)"

lemma Poly_smult:
  fixes f :: "nat \<Rightarrow> 'a::comm_semiring_0"
  shows "f \<in> Poly \<Longrightarrow> (\<lambda>n. a * f n) \<in> Poly"
  unfolding Poly_def
  by (clarify, rule_tac x=n in exI, simp)

lemma coeff_smult [simp]: "coeff (smult a p) n = a * coeff p n"
  unfolding smult_def
  by (simp add: Abs_poly_inverse Poly_smult coeff)

lemma degree_smult_le: "degree (smult a p) \<le> degree p"
  by (rule degree_le, simp add: coeff_eq_0)

lemma smult_smult: "smult a (smult b p) = smult (a * b) p"
  by (rule poly_ext, simp add: mult_assoc)

lemma smult_0_right [simp]: "smult a 0 = 0"
  by (rule poly_ext, simp)

lemma smult_0_left [simp]: "smult 0 p = 0"
  by (rule poly_ext, simp)

lemma smult_1_left [simp]: "smult (1::'a::comm_semiring_1) p = p"
  by (rule poly_ext, simp)

lemma smult_add_right:
  "smult a (p + q) = smult a p + smult a q"
  by (rule poly_ext, simp add: ring_simps)

lemma smult_add_left:
  "smult (a + b) p = smult a p + smult b p"
  by (rule poly_ext, simp add: ring_simps)

lemma smult_minus_right:
  "smult (a::'a::comm_ring) (- p) = - smult a p"
  by (rule poly_ext, simp)

lemma smult_minus_left:
  "smult (- a::'a::comm_ring) p = - smult a p"
  by (rule poly_ext, simp)

lemma smult_diff_right:
  "smult (a::'a::comm_ring) (p - q) = smult a p - smult a q"
  by (rule poly_ext, simp add: ring_simps)

lemma smult_diff_left:
  "smult (a - b::'a::comm_ring) p = smult a p - smult b p"
  by (rule poly_ext, simp add: ring_simps)

lemma smult_pCons [simp]:
  "smult a (pCons b p) = pCons (a * b) (smult a p)"
  by (rule poly_ext, simp add: coeff_pCons split: nat.split)

lemma smult_monom: "smult a (monom b n) = monom (a * b) n"
  by (induct n, simp add: monom_0, simp add: monom_Suc)


subsection {* Multiplication of polynomials *}

lemma Poly_mult_lemma:
  fixes f g :: "nat \<Rightarrow> 'a::comm_semiring_0" and m n :: nat
  assumes "\<forall>i>m. f i = 0"
  assumes "\<forall>j>n. g j = 0"
  shows "\<forall>k>m+n. (\<Sum>i\<le>k. f i * g (k-i)) = 0"
proof (clarify)
  fix k :: nat
  assume "m + n < k"
  show "(\<Sum>i\<le>k. f i * g (k - i)) = 0"
  proof (rule setsum_0' [rule_format])
    fix i :: nat
    assume "i \<in> {..k}" hence "i \<le> k" by simp
    with `m + n < k` have "m < i \<or> n < k - i" by arith
    thus "f i * g (k - i) = 0"
      using prems by auto
  qed
qed

lemma Poly_mult:
  fixes f g :: "nat \<Rightarrow> 'a::comm_semiring_0"
  shows "\<lbrakk>f \<in> Poly; g \<in> Poly\<rbrakk> \<Longrightarrow> (\<lambda>n. \<Sum>i\<le>n. f i * g (n-i)) \<in> Poly"
  unfolding Poly_def
  by (safe, rule exI, rule Poly_mult_lemma)

lemma poly_mult_assoc_lemma:
  fixes k :: nat and f :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> 'a::comm_monoid_add"
  shows "(\<Sum>j\<le>k. \<Sum>i\<le>j. f i (j - i) (n - j)) =
         (\<Sum>j\<le>k. \<Sum>i\<le>k - j. f j i (n - j - i))"
proof (induct k)
  case 0 show ?case by simp
next
  case (Suc k) thus ?case
    by (simp add: Suc_diff_le setsum_addf add_assoc
             cong: strong_setsum_cong)
qed

lemma poly_mult_commute_lemma:
  fixes n :: nat and f :: "nat \<Rightarrow> nat \<Rightarrow> 'a::comm_monoid_add"
  shows "(\<Sum>i\<le>n. f i (n - i)) = (\<Sum>i\<le>n. f (n - i) i)"
proof (rule setsum_reindex_cong)
  show "inj_on (\<lambda>i. n - i) {..n}"
    by (rule inj_onI) simp
  show "{..n} = (\<lambda>i. n - i) ` {..n}"
    by (auto, rule_tac x="n - x" in image_eqI, simp_all)
next
  fix i assume "i \<in> {..n}"
  hence "n - (n - i) = i" by simp
  thus "f (n - i) i = f (n - i) (n - (n - i))" by simp
qed

text {* TODO: move to appropriate theory *}
lemma setsum_atMost_Suc_shift:
  fixes f :: "nat \<Rightarrow> 'a::comm_monoid_add"
  shows "(\<Sum>i\<le>Suc n. f i) = f 0 + (\<Sum>i\<le>n. f (Suc i))"
proof (induct n)
  case 0 show ?case by simp
next
  case (Suc n) note IH = this
  have "(\<Sum>i\<le>Suc (Suc n). f i) = (\<Sum>i\<le>Suc n. f i) + f (Suc (Suc n))"
    by (rule setsum_atMost_Suc)
  also have "(\<Sum>i\<le>Suc n. f i) = f 0 + (\<Sum>i\<le>n. f (Suc i))"
    by (rule IH)
  also have "f 0 + (\<Sum>i\<le>n. f (Suc i)) + f (Suc (Suc n)) =
             f 0 + ((\<Sum>i\<le>n. f (Suc i)) + f (Suc (Suc n)))"
    by (rule add_assoc)
  also have "(\<Sum>i\<le>n. f (Suc i)) + f (Suc (Suc n)) = (\<Sum>i\<le>Suc n. f (Suc i))"
    by (rule setsum_atMost_Suc [symmetric])
  finally show ?case .
qed

instantiation poly :: (comm_semiring_0) comm_semiring_0
begin

definition
  times_poly_def:
    "p * q = Abs_poly (\<lambda>n. \<Sum>i\<le>n. coeff p i * coeff q (n-i))"

lemma coeff_mult:
  "coeff (p * q) n = (\<Sum>i\<le>n. coeff p i * coeff q (n-i))"
  unfolding times_poly_def
  by (simp add: Abs_poly_inverse coeff Poly_mult)

instance proof
  fix p q r :: "'a poly"
  show 0: "0 * p = 0"
    by (simp add: expand_poly_eq coeff_mult)
  show "p * 0 = 0"
    by (simp add: expand_poly_eq coeff_mult)
  show "(p + q) * r = p * r + q * r"
    by (simp add: expand_poly_eq coeff_mult left_distrib setsum_addf)
  show "(p * q) * r = p * (q * r)"
  proof (rule poly_ext)
    fix n :: nat
    have "(\<Sum>j\<le>n. \<Sum>i\<le>j. coeff p i * coeff q (j - i) * coeff r (n - j)) =
          (\<Sum>j\<le>n. \<Sum>i\<le>n - j. coeff p j * coeff q i * coeff r (n - j - i))"
      by (rule poly_mult_assoc_lemma)
    thus "coeff ((p * q) * r) n = coeff (p * (q * r)) n"
      by (simp add: coeff_mult setsum_right_distrib
                    setsum_left_distrib mult_assoc)
  qed
  show "p * q = q * p"
  proof (rule poly_ext)
    fix n :: nat
    have "(\<Sum>i\<le>n. coeff p i * coeff q (n - i)) =
          (\<Sum>i\<le>n. coeff p (n - i) * coeff q i)"
      by (rule poly_mult_commute_lemma)
    thus "coeff (p * q) n = coeff (q * p) n"
      by (simp add: coeff_mult mult_commute)
  qed
qed

end

lemma degree_mult_le: "degree (p * q) \<le> degree p + degree q"
apply (rule degree_le, simp add: coeff_mult)
apply (rule Poly_mult_lemma)
apply (simp_all add: coeff_eq_0)
done

lemma mult_pCons_left [simp]:
  "pCons a p * q = smult a q + pCons 0 (p * q)"
apply (rule poly_ext)
apply (case_tac n)
apply (simp add: coeff_mult)
apply (simp add: coeff_mult setsum_atMost_Suc_shift
            del: setsum_atMost_Suc)
done

lemma mult_pCons_right [simp]:
  "p * pCons a q = smult a p + pCons 0 (p * q)"
  using mult_pCons_left [of a q p] by (simp add: mult_commute)

lemma mult_smult_left: "smult a p * q = smult a (p * q)"
  by (induct p, simp, simp add: smult_add_right smult_smult)

lemma mult_smult_right: "p * smult a q = smult a (p * q)"
  using mult_smult_left [of a q p] by (simp add: mult_commute)

lemma mult_monom: "monom a m * monom b n = monom (a * b) (m + n)"
  by (induct m, simp add: monom_0 smult_monom, simp add: monom_Suc)


subsection {* The unit polynomial and exponentiation *}

instantiation poly :: (comm_semiring_1) comm_semiring_1
begin

definition
  one_poly_def:
    "1 = pCons 1 0"

instance proof
  fix p :: "'a poly" show "1 * p = p"
    unfolding one_poly_def
    by simp
next
  show "0 \<noteq> (1::'a poly)"
    unfolding one_poly_def by simp
qed

end

lemma coeff_1 [simp]: "coeff 1 n = (if n = 0 then 1 else 0)"
  unfolding one_poly_def
  by (simp add: coeff_pCons split: nat.split)

lemma degree_1 [simp]: "degree 1 = 0"
  unfolding one_poly_def
  by (rule degree_pCons_0)

instantiation poly :: (comm_semiring_1) recpower
begin

primrec power_poly where
  power_poly_0: "(p::'a poly) ^ 0 = 1"
| power_poly_Suc: "(p::'a poly) ^ (Suc n) = p * p ^ n"

instance
  by default simp_all

end

instance poly :: (comm_ring) comm_ring ..

instance poly :: (comm_ring_1) comm_ring_1 ..

instantiation poly :: (comm_ring_1) number_ring
begin

definition
  "number_of k = (of_int k :: 'a poly)"

instance
  by default (rule number_of_poly_def)

end


subsection {* Polynomials form an integral domain *}

lemma coeff_mult_degree_sum:
  "coeff (p * q) (degree p + degree q) =
   coeff p (degree p) * coeff q (degree q)"
 apply (simp add: coeff_mult)
 apply (subst setsum_diff1' [where a="degree p"])
   apply simp
  apply simp
 apply (subst setsum_0' [rule_format])
  apply clarsimp
  apply (subgoal_tac "degree p < a \<or> degree q < degree p + degree q - a")
   apply (force simp add: coeff_eq_0)
  apply arith
 apply simp
done

instance poly :: (idom) idom
proof
  fix p q :: "'a poly"
  assume "p \<noteq> 0" and "q \<noteq> 0"
  have "coeff (p * q) (degree p + degree q) =
        coeff p (degree p) * coeff q (degree q)"
    by (rule coeff_mult_degree_sum)
  also have "coeff p (degree p) * coeff q (degree q) \<noteq> 0"
    using `p \<noteq> 0` and `q \<noteq> 0` by simp
  finally have "\<exists>n. coeff (p * q) n \<noteq> 0" ..
  thus "p * q \<noteq> 0" by (simp add: expand_poly_eq)
qed

lemma degree_mult_eq:
  fixes p q :: "'a::idom poly"
  shows "\<lbrakk>p \<noteq> 0; q \<noteq> 0\<rbrakk> \<Longrightarrow> degree (p * q) = degree p + degree q"
apply (rule order_antisym [OF degree_mult_le le_degree])
apply (simp add: coeff_mult_degree_sum)
done

lemma dvd_imp_degree_le:
  fixes p q :: "'a::idom poly"
  shows "\<lbrakk>p dvd q; q \<noteq> 0\<rbrakk> \<Longrightarrow> degree p \<le> degree q"
  by (erule dvdE, simp add: degree_mult_eq)


subsection {* Long division of polynomials *}

definition
  divmod_poly_rel :: "'a::field poly \<Rightarrow> 'a poly \<Rightarrow> 'a poly \<Rightarrow> 'a poly \<Rightarrow> bool"
where
  "divmod_poly_rel x y q r \<longleftrightarrow>
    x = q * y + r \<and> (if y = 0 then q = 0 else r = 0 \<or> degree r < degree y)"

lemma divmod_poly_rel_0:
  "divmod_poly_rel 0 y 0 0"
  unfolding divmod_poly_rel_def by simp

lemma divmod_poly_rel_by_0:
  "divmod_poly_rel x 0 0 x"
  unfolding divmod_poly_rel_def by simp

lemma eq_zero_or_degree_less:
  assumes "degree p \<le> n" and "coeff p n = 0"
  shows "p = 0 \<or> degree p < n"
proof (cases n)
  case 0
  with `degree p \<le> n` and `coeff p n = 0`
  have "coeff p (degree p) = 0" by simp
  then have "p = 0" by simp
  then show ?thesis ..
next
  case (Suc m)
  have "\<forall>i>n. coeff p i = 0"
    using `degree p \<le> n` by (simp add: coeff_eq_0)
  then have "\<forall>i\<ge>n. coeff p i = 0"
    using `coeff p n = 0` by (simp add: le_less)
  then have "\<forall>i>m. coeff p i = 0"
    using `n = Suc m` by (simp add: less_eq_Suc_le)
  then have "degree p \<le> m"
    by (rule degree_le)
  then have "degree p < n"
    using `n = Suc m` by (simp add: less_Suc_eq_le)
  then show ?thesis ..
qed

lemma divmod_poly_rel_pCons:
  assumes rel: "divmod_poly_rel x y q r"
  assumes y: "y \<noteq> 0"
  assumes b: "b = coeff (pCons a r) (degree y) / coeff y (degree y)"
  shows "divmod_poly_rel (pCons a x) y (pCons b q) (pCons a r - smult b y)"
    (is "divmod_poly_rel ?x y ?q ?r")
proof -
  have x: "x = q * y + r" and r: "r = 0 \<or> degree r < degree y"
    using assms unfolding divmod_poly_rel_def by simp_all

  have 1: "?x = ?q * y + ?r"
    using b x by simp

  have 2: "?r = 0 \<or> degree ?r < degree y"
  proof (rule eq_zero_or_degree_less)
    have "degree ?r \<le> max (degree (pCons a r)) (degree (smult b y))"
      by (rule degree_diff_le)
    also have "\<dots> \<le> degree y"
    proof (rule min_max.le_supI)
      show "degree (pCons a r) \<le> degree y"
        using r by (auto simp add: degree_pCons_eq_if)
      show "degree (smult b y) \<le> degree y"
        by (rule degree_smult_le)
    qed
    finally show "degree ?r \<le> degree y" .
  next
    show "coeff ?r (degree y) = 0"
      using `y \<noteq> 0` unfolding b by simp
  qed

  from 1 2 show ?thesis
    unfolding divmod_poly_rel_def
    using `y \<noteq> 0` by simp
qed

lemma divmod_poly_rel_exists: "\<exists>q r. divmod_poly_rel x y q r"
apply (cases "y = 0")
apply (fast intro!: divmod_poly_rel_by_0)
apply (induct x)
apply (fast intro!: divmod_poly_rel_0)
apply (fast intro!: divmod_poly_rel_pCons)
done

lemma divmod_poly_rel_unique:
  assumes 1: "divmod_poly_rel x y q1 r1"
  assumes 2: "divmod_poly_rel x y q2 r2"
  shows "q1 = q2 \<and> r1 = r2"
proof (cases "y = 0")
  assume "y = 0" with assms show ?thesis
    by (simp add: divmod_poly_rel_def)
next
  assume [simp]: "y \<noteq> 0"
  from 1 have q1: "x = q1 * y + r1" and r1: "r1 = 0 \<or> degree r1 < degree y"
    unfolding divmod_poly_rel_def by simp_all
  from 2 have q2: "x = q2 * y + r2" and r2: "r2 = 0 \<or> degree r2 < degree y"
    unfolding divmod_poly_rel_def by simp_all
  from q1 q2 have q3: "(q1 - q2) * y = r2 - r1"
    by (simp add: ring_simps)
  from r1 r2 have r3: "(r2 - r1) = 0 \<or> degree (r2 - r1) < degree y"
    by (auto intro: degree_diff_less)

  show "q1 = q2 \<and> r1 = r2"
  proof (rule ccontr)
    assume "\<not> (q1 = q2 \<and> r1 = r2)"
    with q3 have "q1 \<noteq> q2" and "r1 \<noteq> r2" by auto
    with r3 have "degree (r2 - r1) < degree y" by simp
    also have "degree y \<le> degree (q1 - q2) + degree y" by simp
    also have "\<dots> = degree ((q1 - q2) * y)"
      using `q1 \<noteq> q2` by (simp add: degree_mult_eq)
    also have "\<dots> = degree (r2 - r1)"
      using q3 by simp
    finally have "degree (r2 - r1) < degree (r2 - r1)" .
    then show "False" by simp
  qed
qed

lemmas divmod_poly_rel_unique_div =
  divmod_poly_rel_unique [THEN conjunct1, standard]

lemmas divmod_poly_rel_unique_mod =
  divmod_poly_rel_unique [THEN conjunct2, standard]

instantiation poly :: (field) ring_div
begin

definition div_poly where
  [code del]: "x div y = (THE q. \<exists>r. divmod_poly_rel x y q r)"

definition mod_poly where
  [code del]: "x mod y = (THE r. \<exists>q. divmod_poly_rel x y q r)"

lemma div_poly_eq:
  "divmod_poly_rel x y q r \<Longrightarrow> x div y = q"
unfolding div_poly_def
by (fast elim: divmod_poly_rel_unique_div)

lemma mod_poly_eq:
  "divmod_poly_rel x y q r \<Longrightarrow> x mod y = r"
unfolding mod_poly_def
by (fast elim: divmod_poly_rel_unique_mod)

lemma divmod_poly_rel:
  "divmod_poly_rel x y (x div y) (x mod y)"
proof -
  from divmod_poly_rel_exists
    obtain q r where "divmod_poly_rel x y q r" by fast
  thus ?thesis
    by (simp add: div_poly_eq mod_poly_eq)
qed

instance proof
  fix x y :: "'a poly"
  show "x div y * y + x mod y = x"
    using divmod_poly_rel [of x y]
    by (simp add: divmod_poly_rel_def)
next
  fix x :: "'a poly"
  have "divmod_poly_rel x 0 0 x"
    by (rule divmod_poly_rel_by_0)
  thus "x div 0 = 0"
    by (rule div_poly_eq)
next
  fix y :: "'a poly"
  have "divmod_poly_rel 0 y 0 0"
    by (rule divmod_poly_rel_0)
  thus "0 div y = 0"
    by (rule div_poly_eq)
next
  fix x y z :: "'a poly"
  assume "y \<noteq> 0"
  hence "divmod_poly_rel (x + z * y) y (z + x div y) (x mod y)"
    using divmod_poly_rel [of x y]
    by (simp add: divmod_poly_rel_def left_distrib)
  thus "(x + z * y) div y = z + x div y"
    by (rule div_poly_eq)
qed

end

lemma degree_mod_less:
  "y \<noteq> 0 \<Longrightarrow> x mod y = 0 \<or> degree (x mod y) < degree y"
  using divmod_poly_rel [of x y]
  unfolding divmod_poly_rel_def by simp

lemma div_poly_less: "degree x < degree y \<Longrightarrow> x div y = 0"
proof -
  assume "degree x < degree y"
  hence "divmod_poly_rel x y 0 x"
    by (simp add: divmod_poly_rel_def)
  thus "x div y = 0" by (rule div_poly_eq)
qed

lemma mod_poly_less: "degree x < degree y \<Longrightarrow> x mod y = x"
proof -
  assume "degree x < degree y"
  hence "divmod_poly_rel x y 0 x"
    by (simp add: divmod_poly_rel_def)
  thus "x mod y = x" by (rule mod_poly_eq)
qed

lemma mod_pCons:
  fixes a and x
  assumes y: "y \<noteq> 0"
  defines b: "b \<equiv> coeff (pCons a (x mod y)) (degree y) / coeff y (degree y)"
  shows "(pCons a x) mod y = (pCons a (x mod y) - smult b y)"
unfolding b
apply (rule mod_poly_eq)
apply (rule divmod_poly_rel_pCons [OF divmod_poly_rel y refl])
done


subsection {* Evaluation of polynomials *}

definition
  poly :: "'a::comm_semiring_0 poly \<Rightarrow> 'a \<Rightarrow> 'a" where
  "poly = poly_rec (\<lambda>x. 0) (\<lambda>a p f x. a + x * f x)"

lemma poly_0 [simp]: "poly 0 x = 0"
  unfolding poly_def by (simp add: poly_rec_0)

lemma poly_pCons [simp]: "poly (pCons a p) x = a + x * poly p x"
  unfolding poly_def by (simp add: poly_rec_pCons)

lemma poly_1 [simp]: "poly 1 x = 1"
  unfolding one_poly_def by simp

lemma poly_monom:
  fixes a x :: "'a::{comm_semiring_1,recpower}"
  shows "poly (monom a n) x = a * x ^ n"
  by (induct n, simp add: monom_0, simp add: monom_Suc power_Suc mult_ac)

lemma poly_add [simp]: "poly (p + q) x = poly p x + poly q x"
  apply (induct p arbitrary: q, simp)
  apply (case_tac q, simp, simp add: ring_simps)
  done

lemma poly_minus [simp]:
  fixes x :: "'a::comm_ring"
  shows "poly (- p) x = - poly p x"
  by (induct p, simp_all)

lemma poly_diff [simp]:
  fixes x :: "'a::comm_ring"
  shows "poly (p - q) x = poly p x - poly q x"
  by (simp add: diff_minus)

lemma poly_setsum: "poly (\<Sum>k\<in>A. p k) x = (\<Sum>k\<in>A. poly (p k) x)"
  by (cases "finite A", induct set: finite, simp_all)

lemma poly_smult [simp]: "poly (smult a p) x = a * poly p x"
  by (induct p, simp, simp add: ring_simps)

lemma poly_mult [simp]: "poly (p * q) x = poly p x * poly q x"
  by (induct p, simp_all, simp add: ring_simps)

end
