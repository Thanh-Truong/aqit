;;---PLUS and MINUS---
;; a1.(var = A - prevvar) AND (var theta B) ==> (A-B) theta prevvar
;; a2.(var = A - prevvar) AND (B  theta var) ==> prevvar theta (A - B)
;; Replace var by nv, replace B by prevvar
(defun rule1-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-plus_)
       (or (equal arithvars (list var prevvar A))
	   (equal arithvars (list prevvar var A)))))

(defun rule1-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (list (subst prevvar B (subst nv var comppred))
	(make-predicate _number-plus_ nv B A)))
;;-----------------------------------------------------------------
;; b1.(var =  prevvar - A) AND (var  theta B)==> prevvar  theta (A + B)
;; b2.(var =  prevvar - A) AND (B  theta var)==> B+A theta prevvar
(defun rule2-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-plus_)
       (or (equal arithvars (list A var prevvar))
	   (equal arithvars (list var A prevvar)))))
(defun rule2-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (list (subst prevvar var (subst nv B comppred))
	(make-predicate _number-plus_ A B nv)))
;;---------------------------------------------------------------------
;; c1. (var = prevvar + A) AND (var theta B) ==> prevvar theta B - A    
;; c2. (var = prevvar + A) AND (B theta var) ==> B-A theta prevvar
(defun rule3-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-plus_)
       (or (equal arithvars (list A prevvar var))
	   (equal arithvars (list prevvar A var)))))
(defun rule3-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (list (subst prevvar var (subst nv B comppred))
	(make-predicate _number-plus_ nv A B)))
;;------------------------------------------------------------------
;; ---TIMES (prevvar * A) AND A > 0
;; d1a.(prevvar* A) AND (var theta B) AND A >0
;; ==> (prevvar theta B/A)
;; d1b.(prevvar* A) AND (B theta var) AND A >0
;; ==> (B/A theta prevvar)
(defun rule4-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-times_)
       (or (equal arithvars (list prevvar A var))
	   (equal arithvars (list A prevvar var)))
       (is-positive? A ref)))
(defun rule4-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (list (subst prevvar var (subst nv B comppred))            
	(make-predicate _number-times_ nv A B)))
;;------------------------------------------------------------------
;; d2.a(prevvar* A) AND (var theta B) AND A <0
;; ==> (prevvar theta' B/A)
;; d2.a(prevvar* A) AND (B theta var) AND A <0
;; ==> (B/A theta' prevvar)
(defun rule5-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-times_)
       (or (equal arithvars (list prevvar A var))
	   (equal arithvars (list A prevvar var)))
       (is-negative? A ref)))
(defun rule5-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)	   
 (list (subst (inverse-comp compop) compop 
	      (subst prevvar var (subst nv B comppred)))
       (make-predicate _number-times_ nv A B)))
;;------------------------------------------------------------------
;; d3.a(prevvar* A) AND (var theta B)
;; ==> [OR (prevvar theta B/A) AND A > 0
;;         (prevvar theta' B/A) AND A < 0] 
;; d3.a (prevvar* A) AND (B theta var)
;; ==> [OR (B/A theta prevvar) AND A > 0
;;         (B/A theta' prevvar) AND A < 0] 
(defun rule6-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)	   
  (and (eq arithop _number-times_)
       (or (equal arithvars (list prevvar A var))
	   (equal arithvars (list A prevvar var)))))
(defun rule6-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars) 
  (orify (list (list (subst prevvar var (subst nv B comppred))
		     (make-predicate _number-times_ nv A B)
		     (make-predicate _>_ A 0))			
	       (list (subst (inverse-comp compop) compop 
			    (subst prevvar var (subst nv B comppred)))
		     (make-predicate _number-times_ nv A B)
		     (make-predicate _<_ A 0)))))
;;------------------------------------------------------------------
;; ---DIV A is divisor (prevvar / A) A is positive
;; d4a.(prevvar/ A) AND (var theta B) AND A >0
;; ==> (prevvar theta B*A)
;; d4b.(prevvar/ A) AND (B theta var) AND A >0
;; ==> (B*A theta prevvar)
(defun rule7-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars) 
  (and (eq arithop _number-times_)
       (or (equal arithvars (list var A prevvar))
	   (equal arithvars (list A var prevvar)))
       (is-positive? A ref)))
(defun rule7-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars) 	   
  (list (subst prevvar var (subst nv B comppred))
	(make-predicate _number-times_ A B nv)))
;;------------------------------------------------------------------
;; ---DIV A is divisor (prevvar / A) A is negative
;; d4c.(prevvar/ A) AND (var theta B) AND A <0
;; ==> (prevvar theta' B/A)
;; d4d.(prevvar/ A) AND (B theta var) AND A <0
;; ==> (B*A theta' prevvar)
(defun rule8-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-times_)
      (or (equal arithvars (list var A prevvar))
	  (equal arithvars (list A var prevvar)))
      (is-negative? A ref)))
(defun rule8-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (list (subst (inverse-comp compop) compop 
	       (subst prevvar var (subst nv B comppred)))
	(make-predicate _number-times_ A B nv)))
;;------------------------------------------------------------------
;; ---DIV A is divisor (prevvar / A) A is not known
;; d4e.(prevvar/ A) AND (var theta B) 
;; ==> [OR (prevvar theta B*A A > 0)
;;         (prevvar theta' B*A A < 0)]
;; d4f.(prevvar/ A) AND (B theta var) 
;; ==> [OR (B*A theta prevvar  A > 0)
;;         (B*A theta' prevvar A < 0)]
(defun rule9-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-times_)
       (or (equal arithvars (list var A prevvar))
	   (equal arithvars (list A var prevvar)))))
(defun rule9-RHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (orify (list (list (subst prevvar var (subst nv B comppred))
		     (make-predicate _number-times_ A B nv)
		     (make-predicate _>_ A 0))			
	       (list (subst (inverse-comp compop) compop 
			    (subst prevvar var (subst nv B comppred)))
		     (make-predicate _number-times_ A B nv)
		     (make-predicate _<_ A 0)))))
;;===================================================================
;;--- DIV A is dividen (A / prevvar) AND B = 0
;; d5.a (var= A/prevvar) AND (var theta 0) AND A is positive
;;==> (prevvar theta 0) 
;; d5.b (var= A/prevvar) AND (0 theta var) AND A is positive
;;==> (0 theta prevvar) 
(defun rule10-LHS (  ref 
			   comppred arithpred arithop compop var 
			   prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-times_)
       (or (equal arithvars (list var prevvar A))
	   (equal arithvars (list prevvar var A)))
       (eq B 0)
       (is-positive? A ref)))
(defun rule10-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)
  (list (subst prevvar var (subst nv B comppred))))
;;===================================================================
;; d5.c (var= A/prevvar) AND (var theta 0) AND A is negative
;;==> (prevvar theta' 0) 
;; d5.d (var= A/prevvar) AND (0 theta var) AND A is negative
;;==> (0 theta' prevvar)
(defun rule11-LHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)
  (and (eq arithop _number-times_)
       (or (equal arithvars (list var prevvar A))
	   (equal arithvars (list prevvar var A)))
       (eq B 0)
       (is-negative? A ref)))
(defun rule11-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)   	   
  (list (subst (inverse-comp compop) compop 
	       (subst prevvar var (subst nv B comppred)))))	  
;;===================================================================
;; d5.e (var= A/prevvar) AND (var theta 0) 
;;==> [OR (prevvar theta 0 AND A is positive)
;;        (prevvar theta' 0 AND A is negative)]
;; d5.f (var= A/prevvar) AND (0 theta var) 
;;==> [OR (0 theta prevvar AND A is positive)
;;        (0 theta' prevvar AND A is negative)]
(defun rule12-LHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars) 	   
  (and (eq arithop _number-times_)
       (or (equal arithvars (list var prevvar A))
	   (equal arithvars (list prevvar var A)))
       (eq B 0)))
(defun rule12-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars) 	   
  (orify (list 
	  (list (subst prevvar var (subst nv B comppred))
		(make-predicate _>_ A 0))
	  (list (subst (inverse-comp compop) compop 
		       (subst prevvar var (subst nv B comppred)))
		(make-predicate _<_ A 0)))))
;;===================================================================
;;--- DIV A is dividen (A / prevvar) AND B != 0
;; d6.a (var=A/prevvar) AND (var theta B)
;;==> or - A theta  B* prevvar , prevvar > 0
;;       - A theta' B* prevvar , prevvar < 0
;;==> or -  A/B theta  prevvar , prevvar > 0, B > 0
;;       -  A/B theta'  prevvar , prevvar > 0, B < 0
;;       -  A/B theta' prevvar , prevvar < 0, B > 0
;;       -  A/B theta prevvar , prevvar < 0, B < 0
(defun rule13-LHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars) 	   
  (and (eq arithop _number-times_)
       (or (equal arithvars (list var prevvar A))
	   (equal arithvars (list prevvar var A)))
       (not (eq B 0))
       (eq B (third comppred))))
(defun rule13-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars) 	   
  (orify (list 
	  (list (make-predicate compop nv  prevvar)
		(make-predicate _number-times_ nv B A)
		(make-predicate _>_ prevvar 0)
		(make-predicate _>_ B 0))
	  (list (make-predicate (inverse-comp compop) nv  prevvar)
	       (make-predicate _number-times_ nv B A)
	       (make-predicate _>_ prevvar 0)
	       (make-predicate _<_ B 0))
	  (list (make-predicate (inverse-comp compop) nv  prevvar)
		(make-predicate _number-times_ nv B A)
			 (make-predicate _<_ prevvar 0)
			 (make-predicate _>_ B 0))
	  (list (make-predicate compop nv  prevvar)
		(make-predicate _number-times_ nv B A)
		(make-predicate _<_ prevvar 0)
		(make-predicate _<_ B 0)))))
;;===================================================================
;; d6.b (var=A/prevvar) AND (B theta var)
;;==> or -  B* prevvar theta  A , prevvar > 0
;;       -  B* prevvar theta' A, prevvar < 0		   
;;==> or -  prevvar theta  A/B , prevvar > 0, B > 0
;;       -  prevvar theta' A/B , prevvar > 0, B < 0
;;       -  prevvar theta' A/B , prevvar < 0, B > 0
;;       -  prevvar theta  A/B , prevvar < 0, B < 0
(defun rule14-LHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars) 	   
  (and (eq arithop _number-times_)
       (or (equal arithvars (list var prevvar A))
	   (equal arithvars (list prevvar var A)))
       (not (eq B 0))
       (eq B (second comppred))))
(defun rule14-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars) 
  (orify (list 
	  (list (make-predicate compop  prevvar nv)
		(make-predicate _number-times_ nv B A)
		(make-predicate _>_ prevvar 0)
		(make-predicate _>_ B 0))
	  (list (make-predicate (inverse-comp compop) prevvar nv)
		(make-predicate _number-times_ nv B A)
		(make-predicate _>_ prevvar 0)
		(make-predicate _<_ B 0))
	  (list (make-predicate (inverse-comp compop) prevvar nv)
		(make-predicate _number-times_ nv B A)
		(make-predicate _<_ prevvar 0)
		(make-predicate _>_ B 0))
	  (list (make-predicate compop  prevvar nv)
		(make-predicate _number-times_ nv B A)
		(make-predicate _<_ prevvar 0)
		(make-predicate _<_ B 0)))))
;;===================================================================
;; ---  SQRT ---
;; SQRT(prevvar)  theta B ==> prevvar  theta (power B 2)
(defun rule15-LHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)    
  (eq arithop _number-sqrt_))
(defun rule15-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)    
  (list (make-predicate compop prevvar nv)
	(make-predicate _number-power_ B 2 nv)))
;;===================================================================
;; ---  POWER ---
;; Power(prevvar, A)  theta B ==> prevvar  theta (power B 1/A)
(defun rule16-LHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)    
  (eq arithop _number-power_))
(defun rule16-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)  
  (setq nv1 (dt_genvar (type_of_var var *bindings*)))
  (list (make-predicate compop prevvar nv)
		 (make-predicate _number-times_ nv1 A 1)
		 (make-predicate _number-power_ B nv1 nv)))	
;;===================================================================
;; ---  ABS ---
;; ABS (prevvar) < B ==> prevvar > - B and prevvar < B
(defun rule17-LHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)  
  (and (eq arithop _number-abs_)
       (or (eq compop _<_) (eq compop _<=_))))
(defun rule17-RHS (  ref 
			    comppred arithpred arithop compop var 
			    prevvar A B nv nv1 arithvars)  
  (list (make-predicate compop prevvar B)
	(make-predicate _number-plus_ nv B 0)
	(make-predicate (inverse-comp compop) prevvar nv)))
;;===================================================================
;; ---  ABS ---
;; ABS (prevvar) > B ==> prevvar > B or prevvar < - B
(defun rule18-LHS ( ref 
			comppred arithpred arithop compop var 
			prevvar A B nv nv1 arithvars)  
  (and (eq arithop _number-abs_)
       (or (eq compop _>_) (eq compop _>=_))))
(defun rule18-RHS (  ref 
			 comppred arithpred arithop compop var 
			 prevvar A B nv nv1 arithvars) 
  (orify (list
	  (list (make-predicate compop prevvar B))
	  (list (make-predicate (inverse-comp compop) 
				prevvar nv)
		(make-predicate _number-plus_ nv B 0)))))
