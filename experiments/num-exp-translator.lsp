;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2012 Thanh Truong, UDBL
;;; $RCSfile: num-exp-translator.lsp,v $
;;; $Revision: 1.11 $ $Date: 2012/06/14 15:19:20 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Numerical expression involving inequality should
;; be pushed to SQL string if possible
;;; =============================================================
;;; $Log: num-exp-translator.lsp,v $
;;; Revision 1.11  2012/06/14 15:19:20  thatr500
;;; *** empty log message ***
;;;
;;; Revision 1.10  2012/04/27 14:24:22  thatr500
;;; translate DATE/TIMEVAL only if _arithmetic-date_ is ON
;;;
;;; Revision 1.9  2012/04/19 12:00:31  thatr500
;;; *** empty log message ***
;;;
;;; Revision 1.8  2012/04/18 08:00:38  thatr500
;;; removed 'inference-origin-pred1'
;;;
;;; Revision 1.7  2012/04/16 07:50:14  thatr500
;;; - added '(contain-sql-pattern p fn)' which returns T if pattern p found in
;;;  execution plan of function fn.
;;;
;;; - pushed in operator IN
;;;
;;; Revision 1.6  2012/04/02 13:19:40  thatr500
;;; translate Timeval into SQL string
;;;
;;; Revision 1.5  2012/03/31 18:35:51  thatr500
;;; translate expression having +/- Date
;;;
;;; Revision 1.4  2012/03/30 11:32:09  thatr500
;;; fixed 'duplicate input variables'
;;;
;;; Revision 1.3  2012/03/27 16:25:34  thatr500
;;; fixed bug "Numerical expression involves only arithmetic operations"
;;;
;;; Revision 1.2  2012/03/27 08:37:42  thatr500
;;; Added
;;;  - Reachability from cc can be directly or indirectly
;;;  - Operation : *, /, -
;;;  - Pushing a combination of arithemtic operations
;;;  - Inference a variable's origin predicate where the variable is first
;;;    computed.
;;;
;;; Revision 1.1  2012/03/26 07:39:05  thatr500
;;; added freevars to call-late-tr-rewriters0
;;; ============================================================

;;---------------------------------------------------------------------------------------
;; Capabilities 
;;---------------------------------------------------------------------------------------
(defun relational-translate-numop2 (ds pred env sqlq)
  (let* ((arg1 (predicate-argument 1 pred))
         (arg2 (predicate-argument 2 pred))
         (arg3 (predicate-argument 3 pred))
	 (type1 (get-type arg1 env))       
         (type2 (get-type arg2 env))
         (type3 (get-type arg3 env))
	 (ds1 (if (varsymbolp arg1) (datasource arg1 env)))
	 (ds2 (if (varsymbolp arg2) (datasource arg2 env)))
	 (ds3 (if (varsymbolp arg3) (datasource arg3 env)))
	; at least one argument in a comparison must be a variable from the
        ; source, otherwise there's not much point in pushing the comparison.
	 (ok (or (eq ds1 ds) (eq ds2 ds)(eq ds3 ds))))
    ; at this point one variable may not come from the source. Hence, 
    ; it is an input parameter to the absorbed query fragment.
    ; Bug in generic grouper (TR) (assert ok "Generic grouping did not work")
    (if (and ok (varsymbolp arg1) (neq ds1 ds)) (sqlquery-add-input sqlq arg1))
    (if (and ok (varsymbolp arg2) (neq ds2 ds)) (sqlquery-add-input sqlq arg2))
    (if (and ok (varsymbolp arg3) (neq ds3 ds)) (sqlquery-add-input sqlq arg3))
	  
    ; either way, we have decided whether to absorb or not by now
    (if ok (sqlquery-add-predicate sqlq pred))))

(defun arithmeticp (pred)
  ;; TRUE if p is an arithmetic predicate (plus, minus, times, div
  (in (predicate-operator pred)  
      (list _number-plus_ _number-minus_ _number-times_ _number-div_)))

(defun get-original-pred (var env)
  (let ((varinfo (gethash var env)))
    (if (neq varinfo nil)
        (varinfo-origin (gethash var env))
      nil)))

(defun indirect-reachability (arg pred env)
  (let* (;; origin predicate
	 (orgpred (get-original-pred arg env))
	 ;; list of other variables 	 
	 (lvars (remove arg (cdr orgpred)))
	 res cc-var)    
    (if (neq orgpred pred)	
	(progn
	  ;; eliminate constant
	  (setq lvars (subset lvars (f/l (var) (eq (constantp var) nil))))	  
	  ;; If one of orgpred's arguments  from cc 
	  (setq cc-var 
		(car 
		 (subset 
		  lvars
		  (f/l (var)
		       (and (neq orgpred nil)
			(arithmeticp orgpred)
			(varsymbolp var)
			(datasource var env))))))
	  
	  (cond  ((and 
		   orgpred
		   (arithmeticp orgpred)  lvars cc-var) ;; found cc-var
		  (puthash arg _initiates_ orgpred)
		  (list (datasource cc-var env) cc-var))	   
		 ((and (neq lvars nil)
		       (arithmeticp orgpred))
		  ;; recursive call
		  (while (and (eq res nil) lvars)	      
		    (setq res (indirect-reachability (car lvars) orgpred env))
		    (if res (puthash arg _initiates_ orgpred))
		    (setq lvars (cdr lvars)))	    
		  res)
		 (t nil))))))

(defun direct-reachability (arg env)
  (if (varsymbolp arg) (datasource arg env)))

(defun relational-translate-comparison-relaxing (ds pred env sqlq)
  ;; Inference on orgpred1 orgpred2 env to see if any of the two arguments coming
  ;; from a core cluster function (datasource)
  ;; Unlike relational-translate-comparison, this translation is a bit
  ;; relaxing. One of two arguments of the pred must be rechable from the
  ;; source.
  ;; Reachability means calculating by a sequences of arithmetic predicates
  (let* ((arg1 (predicate-argument 1 pred))
         (arg2 (predicate-argument 2 pred))
	 rc1 rc2 rc )

    ;; If arg1,arg2 is reachable from cc ?
    (setq rc1 (reachable-from-cc arg1 pred env))
    (setq rc2 (reachable-from-cc arg2 pred env))
    
    ;; Push this pred if one of two arguments is reachable from cc
    (setq rc (or (eq (first rc1) ds) (eq (first rc2) ds)))
    ;; If an argument is not computed from cc, it is an input of
    ;; this pred
    (if (and rc (varsymbolp  arg1)
	     (varsymbolp (second rc1))
	     (neq (first rc1) ds))
	  (sqlquery-add-input sqlq arg1))


    (if (and rc (varsymbolp  arg2)
	     (varsymbolp (second rc2))
	     (neq (first rc2) ds))
	(sqlquery-add-input sqlq arg2))

    
    ;; Push it or not?
    (if rc (sqlquery-add-predicate sqlq pred))))


(defun reachable-from-cc (arg pred env)
  ;; Rechability from cc is either directly or indirectly
  (let* ((ds (direct-reachability arg env))) ;; is it direct reachability from cc ?
    (if (and (eq ds nil) (varsymbolp arg))
	(indirect-reachability arg pred env)      ;; otherwise, is it indirect reachbility ?
      (list ds arg))))


(defun constant-arrayp (a)
  (and (arrayp a)
       (every (f/l (e) (constantp e)) (arraytolist a))))

(defun element-in-array-to-string (e last)  
  (concat (if (stringp e) "'" "")  e (if (stringp e) "'" "")  (if (not last) "," "")))

(defun constant-array-to-string (a)
  (let* ((l (arraytolist a))
	(end (car (last l))))
    (concat "("
	    ;; all elements but not last
	    (apply 'concat (mapcar (f/l (e)
					(element-in-array-to-string e nil))
				   (butlast l)))
	    (element-in-array-to-string end t)
	    ")")))

(defun sql-literal-strings0 (q pred tablealiases)
  "Generate SQL references to arguments of predicate PRED in SQL query Q"
  (mapcar (f/l (a)
	       (let* ((dppred (gethash a  _initiates_ )))		 
		 (cond ((neq dppred nil)
			;; subsitute a by infix-string from dppred
			(let* ((fno (predicate-operator dppred))
			       (sqlop (getfunction-firsttuple _sqlop_ (list fno)))
			       (op (first sqlop))
			       (infix (second sqlop))
			       (hasvalue (third sqlop)))
			  (sql-incomplete-infix-call op q dppred a  tablealiases)))
		       ((and (datep a) _arithmetic-date_) 
			(date-to-string a))
		       ((and (timevalp a) _arithmetic-date_) 
			(timeval-to-string a))
		       ((constant-arrayp a) (constant-array-to-string a))
		       (t (eq dppred nil) (make-literal-string q a tablealiases))))) 
	  (predicate-arguments pred)))

;; infix         : a op b = c
;; incomple infix: a op b
(defun sql-incomplete-infix-call (op q pred but-not tablealiases)
  "Construct call to infix SQL function"
  (let ((fno (predicate-operator pred))
        (args (sql-literal-strings q (remove but-not pred) tablealiases))
	(pos (car (list-positions but-not pred))))
    (if (string= op "+")
	(setq op (cond ((eq pos 3) "+") ((eq pos 2) "-") ((eq pos 1) "-"))))
    (if (string= op "*")
	(setq op (cond ((eq pos 3) "*") ((eq pos 2) "/") ((eq pos 1) "/"))))
    (if (or (eq pos 2) (eq pos 1))
	(setq args (reverse args)))
    (concat "(" (concat (infix-string op args)) ")")))

(defun filter-out-untranslated-preds1 (untranslated env) 
  (if  *enable-num-exp-trans*
      (progn 
	(maphash (f/l (k pred)
		      (if (some (f/l (p) (equal p pred)) untranslated)
			  (setq untranslated (remove pred untranslated)))) _initiates_)))	
  untranslated)

  
;;---------------------------------------------------------------------------
;;---------------------------------------------------------------------------
(defun relational-translate-in (ds pred env sqlq)
  (let* ((arg1 (predicate-argument 1 pred))
         (arg2 (predicate-argument 2 pred))
	 (type1 (get-type arg1 env))       
         (type2 (get-type arg2 env))
	 (ds1 (if (varsymbolp arg1) (datasource arg1 env)))
	 (ds2 (if (varsymbolp arg2) (datasource arg2 env)))
	; at least one argument in a comparison must be a variable from the
        ; source, otherwise there's not much point in pushing the comparison.
	 (ok (or (eq ds1 ds) (eq ds2 ds))))
    ; at this point one variable may not come from the source. Hence, 
    ; it is an input parameter to the absorbed query fragment.
    ; Bug in generic grouper (TR) (assert ok "Generic grouping did not work")
    (if (and ok (varsymbolp arg1) (neq ds1 ds)) (sqlquery-add-input sqlq arg1))
    (if (and ok (varsymbolp arg2) (neq ds2 ds)) (sqlquery-add-input sqlq arg2))
	  
    ; either way, we have decided whether to absorb or not by now
    (if ok (sqlquery-add-predicate sqlq pred))))
;;---------------------------------------------------------------------------------------
;; Some misc functions
;;---------------------------------------------------------------------------------------
(defun inference-origin-preds0 (preds env)
  (let* (lvars p)
    ;; find all variables needed to be present in _initiates_
    (maphash (f/l (v orgpred)
		  (mapc (f/l (var)
			     (if (and (varsymbolp var)
				      (not (gethash var _initiates_))
				      (not (varinfo-entity (gethash var env))))
				 (setf lvars (adjoin var lvars))))
			(remove v (cdr orgpred))))
		  _initiates_)
    ;; inference 
    (mapc (f/l (var)
	       (setq p (varinfo-origin (gethash var env)))
	       (if (arithmeticp p)
		   (puthash var _initiates_ p))) lvars)
    ))


;; Move some system definitions
(setq *enable-num-exp-trans* t)
(movd 'sql-literal-strings0 'sql-literal-strings)
(movd 'filter-out-untranslated-preds1 'filter-out-untranslated-preds0)
(movd 'inference-origin-preds0 'inference-origin-preds)

;;---------------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------------
;; Binding pattern 'bb' is handled by Martin code
(osql "set :abs = 'relational-translate-comparison-relaxing';       
       set :re  = 'Relational';
       set :lt  = 'OBJECT.OBJECT.<->BOOLEAN';
       set :gt  = 'OBJECT.OBJECT.>->BOOLEAN';
       set :lte  = 'OBJECT.OBJECT.<=->BOOLEAN';
       set :gte  = 'OBJECT.OBJECT.>=->BOOLEAN';
       set :in   = 'VECTOR.IN->OBJECT';
       set :in_translate = 'relational-translate-in';

       create_capability(:re, :lt, 'bf', :abs);
       create_capability(:re, :lt, 'fb', :abs);
       create_capability(:re, :lt, 'ff', :abs);

       create_capability(:re, :lte, 'bf', :abs);
       create_capability(:re, :lte, 'fb', :abs);
       create_capability(:re, :lte, 'ff', :abs);

       create_capability(:re, :gt, 'bf', :abs);
       create_capability(:re, :gt, 'fb', :abs);
       create_capability(:re, :gt, 'ff', :abs);

       create_capability(:re, :gte, 'bf', :abs);
       create_capability(:re, :gte, 'fb', :abs);
       create_capability(:re, :gte, 'ff', :abs);


      set :abs  = 'relational-translate-numop2';
      set :plus = 'number.number.plus->number'; 
      set :times = 'number.number.times->number'; 
      create_capability(:re, :plus,  'bbb', :abs);
      create_capability(:re, :times, 'bbb', :abs);
      create_capability(:re, :in, 'bf', :in_translate);

      sqloperator(:times, '*',true,true, false);
      sqloperator(:plus, '+',true,true, false);      
      sqloperator(:in, 'in', true, false, true);
 ")


