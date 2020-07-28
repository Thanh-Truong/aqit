(defun aqit-supported-indexes ()
  (if (null (getfunctionnamed 'rewritableIndexes t))
      _aqit-supported-indexes_
    (mapcar (f/l (e) (mksymbol (car e)))
	    (getfunction 'rewritableIndexes nil))))

(defun aqit-gcp (pred)
  "Pull up common predicates"
  (cond ((atom pred) pred)
	((conjunctionp pred) pred)
	((disjunctionp pred) 
	 (let* ((cpreds (intersectionl (cdr pred)));; common predicates
		newb newpred)
	   (setq cpreds (remove 'AND cpreds))
	   ;; remove common preds in all branches
	   (setq newpred
		 (orify (mapcar (f/l (b) 
				      ;; conjunction / disjunction/list of predicates
				     (if (or (disjunctionp b)
					     (conjunctionp b)
					     (and (listp b)
						  (predicate-p (first b))))
					 (set-difference b cpreds)
				       b))
				(cdr pred))))
	   (andify (append cpreds (list newpred)))))))			   

(defun some-index-of-kind (fno kind)
  "Test is FNO has some index of KIND"
  (and (relationp fno)
       (isome (relation-indexes fno)
              (f/l (i)(eq (index-type i) kind)))))

(defun indexes-of-kind (fno kind &optional noerror)
  "Return a list of the indexes of a given kind associated with FNO"
  (cond ((relationp fno);; FNO must be a relation
	 (subset (relation-indexes fno);; All indexes of relation FNO
		 (f/l (i)(eq (index-type i)
			     kind))))
        (noerror nil);; return NIL if NOERROR flag true and no index found
        (t (amos-error fno " has no " kind " index"))))

(defun member-of-list (x l)
  "x is member of list l"
  (some (f/l (e) (equal-lists x e)) l))
   
(defun equal-lists (l1 l2)
  "Compare two lists regardless ordering"
  (cond ((eq l1 l2));; Very quick address comparison
        ((and (compound-type l1 'OR)    ;; disjunctions ?
	      (compound-type l2 'OR))
	 (equal-lists (cdr l1) (cdr l2)))
	((and (compound-type l1 'AND) 	;; conjunctions
	      (compound-type l2 'AND))
	 (equal-lists (cdr l1) (cdr l2)))
	((and (listp l1)  (listp l2)    ;; lists ?
	      (= (length l1) (length l2)))
	 (every (f/l (i)  (member-of-list i l2)) l1))
	;; basic types
	(t (equal l1 l2))))
(defun compound-type (cmp op)
  (and (compound-p cmp) (eq (first cmp) op)))

(defun complete-iip (iip)
  "Return T if iip ends with inequality comparison node"
  (let ((p (if (and (neq iip nil)
		    (node-p (car iip)))
	       (node-pred (car iip))))
	op)
    (and (eq (length p) 3)
	 (memq (setq op (generic-fnname (car p)))
	       '(< <= > >=)))))

(defun distribute (lp l)
  "Distribute a list lp into predicate l"
  (cond ((null l) nil)
	((disjunctionp l) 
	 (orify (mapcar (f/l (b)
		      (distribute lp b))
			(cdr l))))
	((conjunctionp l)
	 (andify (append2 lp (cdr l))))
	((listp l) 
	 (unique (append lp l)))
	((symbolp l) (andify (cons l lp)))
	(t (error "Error in distribute function"))))

(defun first-indexed-pred (conj iv)
  "Get the first indexed pred from given conjunction"
  (car (unique 
	(remove nil 
	 (subset (remove nil conj)
		 (f/l (p)
		      (and (predicate-p p)
			   (in iv (predicate-arguments p))
			   (or (get-ccindex (car p))
			       (some (f/l (type) 
					  (and (neq type nil) (indexes-of-kind (car p) type t)))
				     (aqit-supported-indexes))))))))))

(defun sort-indexes (pairs)
  (sort pairs 
	(f/l (a b)
	     ;; weight each pair based on its cardinality
	     (let* ((idxa (first a)) (idxb (first b))
		      (wa (if (ccindex-p idxa)  (ccindex-cardinality idxa)
			    (index-cardinality idxa)))
		      (wb (if (ccindex-p idxb)  (ccindex-cardinality idxb)
			    (index-cardinality idxb))))
	       (< wa wb)))))
  

;; 2013-10-19 Need to sort indexes descending on their cardinalities
(defun find-pairs-of-index-variable (conj)
  "Return pairs of (index variable) sorted by their cardinalities"
  (let (idx v pairs op type)
    (mapc (f/l (p)
	       (cond ((relationp (car p))
		      (dolist (type (aqit-supported-indexes))
			(if (and (ilistp p)
				 (predicate-p p)
				 (setq idx (indexes-of-kind (car p) type t)))
			    (progn 
			      (dolist (id idx)
				(setq v (predicate-argument 
					 (+ 1 (index-pos id)) p))
				(setq pairs (adjoin (list id v) pairs)))))))
		     ((and (neq (car p) 'OPTIONAL)
			   (core-cluster-fn? (car p)))
		      (setq idx (get-ccindex (car p)))
		      (cond (idx
			     (setq v (nth (+ (ccindex-pos idx) 1) p))
			     (setq pairs (adjoin (list idx v) pairs)))))))
	  conj)
    ;;Sort pairs and return
    (if (neq pairs nil) (sort-indexes pairs))))
    ;;pairs))


(defun find-indexed-variables (conj)
  "Return indexed variables in a conjunction"
  (let ((pairs ;; find all pairs (index - variable)
	 (find-pairs-of-index-variable conj)))    
    (remove nil 
     (unique (mapcar ;; loop and return list of variables only
	      (f/l (i)
		   (second i))
	      pairs)))))

(defun not-exposed-indexed-variables (conj)
  "Return not yet exposed indexed variables in a conjunction"
  (let ((lv (find-indexed-variables conj))
	nelv op)
    (dolist (v lv)
      (if (notany (f/l (q) ;; not exposed yet
		       (and 
			(predicate-p q)
			(in v (predicate-arguments q))
			(memq (setq op (generic-fnname (car q)))
			      '(< <= > >=))))
		  conj)
	  (setq nelv (adjoin v nelv))))
    nelv))

(defun first-not-exposed-indexed-variable (conj)
  "Return first not yet exposed indexed variable in a conjunction"  
  (car (not-exposed-indexed-variables (remove nil conj))))

(defun arithmetic-pred? (pred)
  "Return T if pred is arithemtic predicate"
  (in (car pred) (list _number-plus_ _number-minus_ _number-times_
		       _number-div_ _number-power_ _number-sqrt_ _number-abs_)))

(defun connected (q v &optional rest) 
  (and v
       (predicate-p q)
       (in v (predicate-arguments q))
       (or (arithmetic-pred? q)
	   (in (car q) _distance-predicates_)
	   (and (or (in (car q) _gt-comparisons_)
		    (in (car q) _lt-comparisons_))
		(not (in (car (remove v (cdr q)))  (find-indexed-variables rest))))))) 

(defun find-inequal-preds (conj)
  "Find inequality (comparison) predicates"
  (subset conj (f/l (p) 
		    (and (predicate-p p)
			 (or (in (car p) _gt-comparisons_)
			     (in (car p) _lt-comparisons_)
			     )))))
			     
(defun copy-arec (a)
  (make-arec :iip (arec-iip a) :rest (arec-rest a) :visited (arec-visited a)))

(defun iip-to-list (iip)
  "Return list of predicates in iip"
  (remove nil (mapcar (f/l (n) (node-pred n)) iip)))

(defun no-intermediate-nodes (iip)  
  (or (and (complete-iip iip)
	   (= (length iip) 2))
      (and (complete-iip iip)
	   (= (length iip) 3)
	   (let* ((node (second iip))
		  (p (node-pred node)))
	     (in (predicate-operator p) _distance-predicates_)))))
 
(defun inverse-comp (ineq)
  "From GT/GE to LT/LE and vice versa."
  (cond ((eq ineq _>_)  _<_);; GT -->LT
	((eq ineq _>=_) _<=_);; GE -->LE
	((eq ineq _<_)  _>_);; LT -->GT
	((eq ineq _<=_) _>=_);; LE -->GE
	(t ineq))) ;; Otherwise leave as it is
(defun is-positive? (v conj)
  (or (and (constantp v) (> v 0))
      (some (f/l (p) (or 
		      (and ;; x >0, x >= 0
		       (eq v (second p))  
		       (eq (first p) _>_)    
		       (and (numberp (third p)) 
			    (>= (third p) 0)))
		      ;; 0 < X 
		      (and 
		       (eq v (third p))
		       (eq (first p) _<_)			      
		       (and (numberp (second p))
			    (>= (second p) 0)))
		      		      ;; result of ABS
		      (and (eq (car p) _number-abs_)
			   (eq v (car (last p))))
		      ;; result of distance computation
		      (and (in (predicate-operator p) _distance-predicates_)
			   (eq v (car (last p))))
		      ))			      
	    conj)))

(defun is-negative? (v conj)
  (or (and (constantp v) (< v 0))   
      ;; c - exists a guard v < 0 or 0 > v
      (some (f/l (p) (or (and (eq (first p) _<_) ;; X < 0 or 0 > X
			      (eq v (second p))
			      (and (numberp (third p)) 
				   (<= (third p) 0)))
			 (and (eq v (third p))
			      (eq (first p) _>_)
			      (and (numberp (second p))
				   (>= (second p) 0)))))		      
	    conj)))

(defun simplify-division-tester (conj) 
 "TRUE if it could simplify division (x +- a) / x <--> (1 +- a/x)"
 (let (pos+ pos/ res)
   (setq pos+ 0)
   (dolist (p conj)
     (cond ((predicate-plus-p p) ;; PLUS
	    (setq pos/ 0)
	    (dolist (q conj)
	      (cond ((and (predicate-times-p q) ;; TIMES
			  (= (length (intersection-args p q)) 2) ;; common vars
			  (in (car (last q))    ;; last var in q is a common var		      
			      ;; implies --> DIVISION			      
			      (intersection-args p q))
			  ;; should not be constant since it is the result of PLUS 
			  (not (constantp (car (last q)))))	  
		     (setq res (list pos+ pos/))))		     		     
	      (setq pos/ (+ pos/ 1)))))
     (setq pos+ (+ pos+ 1)))
   res))
(defun simplify-division-writer (dv conj)
  (let* ((pos+ (first dv)) 
	 (pos/ (second  dv)) 
	 (oplus (nth pos+ conj))
	 (otimes (nth pos/ conj))
	 (cm-vars (intersection-args oplus otimes))
	 (a  (car (set-difference (cdr oplus) cm-vars)))
	 (v2 (car (set-difference (cdr otimes) cm-vars)))
	 (v1 (car (last (cdr otimes))))
	 (x  (car (remove v1 cm-vars)))
	 newplus newtimes newconj)
    (cond ( ;; (a + x) / x
	   (and (or (equal (list a x v1) (cdr oplus))
		    (equal (list x a v1) (cdr oplus)))
		(or (equal (list v2 x v1) (cdr otimes))
		    (equal (list x v2 v1) (cdr otimes))))
	   (setq newplus  (list _number-plus_  v1 1 v2))
	   (setq newtimes (list _number-times_ v1 x a)))
	  (;; (x - a) / x
	   (and (or (equal (list v1 a x) (cdr oplus))
		    (equal (list a v1 x) (cdr oplus)))
		(or (equal (list v2 x v1) (cdr otimes))
		    (equal (list x v2 v1) (cdr otimes))))
	   (setq newplus  (list _number-plus_  v1 v2 1))
	   (setq newtimes (list _number-times_ v1 x a)))
	  (;;(a-x)/x
	   (and (or (equal (list v1 x a) (cdr oplus))
		    (equal (list x v1 a) (cdr oplus)))
		(or (equal (list v2 x v1) (cdr otimes))
		    (equal (list x v2 v1) (cdr otimes))))
	   (setq newplus  (list _number-plus_  v2 1 v1))
	   (setq newtimes (list _number-times_ v1 x a)))
	  (t 
	   (setq newplus  oplus)
	   (setq newtimes otimes)))
    ;; Use newtimes, newplus instead of the odd ones
    (setq newconj (subst newtimes otimes conj))
    (subst newplus  oplus newconj)))

(defun common-predicate (p v l)
  "p is common predicate in l if its variable v is used
   in some predicates in l"
  (and (ilistp l) 
       (neq v nil)
       (subset l (f/l (q) (and (ilistp q) (in v (cdr q)))))))

(defun update-iip (iip resl)
  "Return new iip"
  ;; Update iip: - remove inequality node, arithmetic node
  ;;             - add    new inequality node 
  (cons (make-node :pred (first resl) :arc nil) (cdr (cdr iip))))

(defun update-rest (iip rest resl)
  "Return new rest"
  (let* ((nrest (append rest (cdr resl)))
	(arithnode (second iip))
	(arithpred (node-pred arithnode))
	(v (node-arc arithnode)))
    (if (common-predicate arithpred  v rest)
	(setq nrest (cons arithpred nrest)))
    nrest))

(defun new-arec (irec b)
  (make-arec :iip (update-iip (arec-iip irec) b) 
	     :rest (update-rest (arec-iip irec) (arec-rest irec) b)))

(defun make-predicate (op &rest vars)
  "Make a predicate from given op and list of vars"
  (cons op vars))

(defun test-LHS (rule irec)
  (let* ((iip (arec-iip irec))
	 (compnode (first iip))
	 (arithnode (second iip))
	 (rest (arec-rest irec))
	 (prevnode (third iip))
	 (ref (arec-rest irec))
	 (comppred (node-pred compnode))
	 (arithpred (node-pred arithnode))
	 (arithop (predicate-operator arithpred))
	 (compop (predicate-operator comppred))
	 (var (node-arc arithnode))
	 (prevvar (node-arc prevnode))
	 (A (car (remove var (remove prevvar (rest arithpred)))))
	 (B (car (remove var (rest comppred))))
	 (nv (dt_genvar (type_of_var var *bindings*)))
	 nv1
	 (arithvars (cdr arithpred)))
    (funcall (first rule) 
	     ref 
	     comppred arithpred arithop compop var 
	     prevvar A B nv nv1 arithvars)))

(defun apply-RHS (rule irec)
  (let* ((iip (arec-iip irec))
	 (compnode (first iip))
	 (arithnode (second iip))
	 (rest (arec-rest irec))
	 (prevnode (third iip))
	 (ref (arec-rest irec))
	 (comppred (node-pred compnode))
	 (arithpred (node-pred arithnode))
	 (arithop (predicate-operator arithpred))
	 (compop (predicate-operator comppred))
	 (var (node-arc arithnode))
	 (prevvar (node-arc prevnode))
	 (A (car (remove var (remove prevvar (rest arithpred)))))
	 (B (car (remove var (rest comppred))))
	 (nv (dt_genvar (type_of_var var *bindings*)))
	 nv1
	 (arithvars (cdr arithpred)))
    (funcall (second rule) 
	     ref 
	     comppred arithpred arithop compop var 
	     prevvar A B nv nv1 arithvars)))

(defvar _aqit-algebraic-rules_ 
  (list '(rule1-LHS rule1-RHS)  '(rule2-LHS rule2-RHS) '(rule3-LHS rule3-RHS)
	'(rule4-LHS rule4-RHS)  '(rule5-LHS rule5-RHS) '(rule6-LHS rule6-RHS)
	'(rule7-LHS rule7-RHS)  '(rule8-LHS rule8-RHS) '(rule9-LHS rule9-RHS)
	'(rule10-LHS rule10-RHS)  '(rule11-LHS rule11-RHS) '(rule12-LHS rule12-RHS)
	'(rule13-LHS rule13-RHS)  '(rule14-LHS rule14-RHS) '(rule15-LHS rule15-RHS)
	'(rule16-LHS rule16-RHS)  '(rule17-LHS rule17-RHS) '(rule18-LHS rule18-RHS)))
