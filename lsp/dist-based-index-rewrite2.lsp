;; Debug 'sp-index-rewrite' printting
(defparameter *print-index-rewrite* nil)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General index rewriter utility functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;------------------------------------------------------------------------  
(defglobal _extract_keyvalue_fn_
  (getfunctionnamed 'OBJECT.EXTRACTKEYVALUE->VECTOR)
  "Extract the first vector from the list if possible")
;;------------------------------------------------------------------------
(defglobal _distance-comparisons_
  (mapcar (function getfunctionnamed)
	  '(object.object.<->boolean object.object.<=->boolean))
  "The comparison pattern that can be rewritten using sp index")
(defun dist-starting-pred? (pred)
  (in (first pred) _distance-predicates_))

;;------------------------------------------------------------------------
(defglobal _distance-other-comparisons_
  (mapcar (function getfunctionnamed)
	  '(object.object.>->boolean object.object.=->boolean 
				     object.object.>=->boolean  
				     object.object.!=->boolean))
  "The other comparison that cannot be rewritten using sp index")
;;-----------------------------------------------------------------------
(defun find-given-point (dpcall this)
  "Distance Predicate V1 V2 
  - case 1 : V1 is a constant, V2 from this --> V1
  - case 2 : V2 is a constant, V1 from this --> V2
  - case 3 : V1 from this, V2 is unknown YES --> V2
  - case 4 : V2 from this, V1 unknown YES -->V2
  - case 5 : V1, V2 not from this --> NIL
 "
  (let* ((v1 (second dpcall))
	 (v2 (third dpcall))
	 (lvars (cdr this))
	 )
    (cond ((and (osql-constantp v1) (in v2 lvars)) v1)
	  ((and (osql-constantp v2) (in v1 lvars)) v2)
	  ((and (in v1 lvars) (not (in v2 lvars))) v2)
	  ((and (in v2 lvars) (not (in v1 lvars))) v1)
	  (t nil))))
;;Main function
(defun rewrite-distance-based-index (conj indxpreds) 
  "Rewrite distance-based-index by index operation
   For each indexed predicated idxpred
       For each supported index types idxtype
          if there is such an index type idxtype on idxpred
                 call rewrite-distance-based-index-by-am
                 which tries to replace a triple 
                             (idxpred, distance predicate, and inequality) 
                        if they are inter-connected. 

  "
  (let* (this indxl rest (rwconj conj)) 
    (dolist (idxpred indxpreds);; For each indexed predicate
      (cond ((in idxpred rwconj) 
	     (setq this idxpred)
	     ;; Remove this
	     (setq rest (remove this rwconj))      
	     (dolist (idxtype _aqit-supported-indexes_);; For each supported index type
	       (setq indxl (indexes-of-kind (car this) idxtype t))
	       (cond ((neq indxl nil)
		      ;; Replace a triple of (indexed predicate, distance predicate, inequality) 
		      ;; by according index access method
		      (setq rwconj
			    (rewrite-distance-based-index-by-am 
			     this indxl rest))
		      ;; If rewrite fails, undo the removing 'this' predicate
		      (cond ((eq rwconj rest)
			     (setq rwconj (adjoin this rwconj)))
			    ((null rwconj)
			     (setq rwconj (adjoin this rest)))
			    ;; When rewrite is done successfully.
			    (t nil)))))))) 
    ;; return rewritten conj
    rwconj))
;;-------------------------------------------------------------------------
(defun multi-phases-to-replace-distance-based-index 
  (this   ;; ?? 
   indxl  ;; list of indexes
   rest   ;; the rest of predicates 
   dpcall ;; distance computation (euclid, minkowski, manhattan)
   )
  (let* ((bnd (cdr this))       ;; list of variables
	 (xind (car indxl))	;;only one AQIT supported index per table supported
	 (pos (index-pos xind)) ;; Position of index in THIS
	 (var (nth pos (cdr this)));; Variable or constant at index position
	 (distance-compcalls ;;calls to comparison with returned value of distance 
	                     ;; predicate
	  (subset rest
		  (f/l (pred) 
		       (and (consp pred)
			    (memq (car pred) _distance-comparisons_)
			    ;;comparison connected to dpcall
			    (intersection (cdr dpcall) (cdr pred))))))
	 ;;pick one of distance-compcalls
         (compcall (car distance-compcalls))
	 (list-other-compcall;;get other comparisions  
	  (subset rest (f/l (pred)
			    (and (consp pred)
				 (memq (car pred) _distance-other-comparisons_)
				 (intersection (cdr dpcall) 
					       ;;comparison connected to dpcall
					       (cdr pred))))))
	 
	 );;end of let
    ;(help 'me)
    (cond ((and (not (null dpcall))
		(not (null compcall)))
           (let* (dt ;; xxdistance from candidate object to search ob
		   (given_point (find-given-point dpcall this))
		   candidate_point
		   ;; AM function
		   (amfn (get-amfn (index-type xind) (car dpcall)))
		   dist-bnd   ;; distance is returned ?		   
		   tmp)
	     (cond ((and (neq given_point nil) (neq amfn nil))
		    ;;------------------------------------------------------------------
		    ;; Phase 1 : Filtering (see rewrite-index-phases.lsp)
		    ;;------------------------------------------------------------------
		    (setq tmp (index-filtering dpcall this xind compcall rest))
		    (setq rest (first tmp))
		    (setq candidate_point (second tmp))
		    (setq dt (third tmp))
		    (setq dist-bnd (fourth tmp))
		    
		    ;;-----------------------------------------------------------------
		    ;; Phase 2 : Refinement  (see rewrite-index-phases.lsp) 
		    ;;-----------------------------------------------------------------
		    (setq rest (index-refinement dpcall compcall given_point 
						 candidate_point dt dist-bnd rest)) 
		    ;;-----------------------------------------------------------------
		    ;; Phase 3 : Synchronization  (see rewrite-index-phases.lsp)
		    ;;----------------------------------------------------------------
		    (setq rest (indexing-synchronization distance-compcalls compcall 
							 list-other-compcall 
							 dpcall compcall dt 
							 dist-bnd rest))
		    
		    )))))
    ;; return 'rewritten' conjunction
    rest))
;;--------------------------------------------------------------------------
;; Rewrite distance-based-index  by AM
;; this - indexed predicate
;; indxl - list of indexes on this
(defun rewrite-distance-based-index-by-am (this indxl rest)
  (let* ((xind (car indxl)) ;; assume there is one index	      
	 (pos (index-pos xind))       ;; Position of index in THIS
	 (var (nth pos (cdr this)))   ;; Variable or constant at 
	                              ;; index position
	 ;; distance preds
         (distpreds               
	  (subset 
	   rest 
	   (f/l (pred)
		 (and (consp pred)    ;; Skip variables in REST
		      (dist-starting-pred? pred)))))
	 
	 newconj ;; to store rewritten conjunction
	 ;; If more distance computation call  were lately added in 2.1, either its 
	 ;; second param or its third param is computed by EXTRACTKEYVALUE funcall.
	 ;; This fact is used to skip unneccessary rewrite rounds
	 (extract_preds
	  (subset rest (f/l (pred) (eq _extract_keyvalue_fn_ (first pred))))))	 
    ;; Rewrite distance inequality to AM  of sp index
    ;; if possible
    (dolist (dpcall distpreds)
      (cond ((and (in dpcall rest)
		  (or (null extract_preds) 
		      (not  (or (eq (second dpcall) (third dpcall))
				(eq (third dpcall) (third dpcall))))))
	     (setq newconj (multi-phases-to-replace-distance-based-index  
			    this indxl rest dpcall))
	     (setq rest newconj))))
    newconj));; return 'modified' conjunction or NULL

(defun aqit-tester-b-c (p distpred)
  "Exists a relation predicate on which there is an AQIT supported index, and
   that index has its subsitute access method to be replaced"
  (some (f/l (idxtype) 
	     (and 
	      (indexes-of-kind (car p) idxtype t)
	      (neq (get-amfn idxtype (car distpred)) nil)))
	_aqit-supported-indexes_))


(defun distance-based-index-tester (pred conj)
  "Rewrite this conjunction if these requirements hold
   AND a)  Exists an inequality predicate
       b)  Exists a stored function predicate on 
           which there is an AQIT supported index such as XTREE, KDTREE,...
       c)  There is a rewrite rule on (car pred): distance predicate 
       For example: 
       If (car pred) is EUCLID then there exists 
         add_index_rewrite_rule('XTREE', #'euclid', #'XTREE_DISTANCE_SEARCH_FN')
       If (car pred) is MINKOWSKI then there exists 
         add_index_rewrite_rule('XTREE', #'minkowski', #'XTREE_DISTANCE_SEARCH_FN')
  "
  (let* (indxpredl (distpred pred))
    (cond ((and  (find-inequal-preds conj)
		 (setq indxpredl
		       (subset conj
			       (f/l (p)
				    (and (ilistp p)
					 ;; b and c
					 (aqit-tester-b-c p distpred))))))		 
	   ;; Return indexed predicates
	   (remove nil indxpredl)))))


(defun distance-based-index-rewriter (pred conj indxpreds freevars)
  (let (nconj dpcalls ldvars rwconj)
    (setq dpcalls (subset conj
			  (f/l (p)
			       (and (consp p)    
				    (dist-starting-pred? p)))))
    ;; collect a list of distance variable dv. We assume d(x, y)->dv
    (dolist (dp dpcalls)
      (setq ldvars (cons (car (last dp)) ldvars)))
    ;; Make sure an inequality pred that use dv in form "dv inequality something"
    ;; nconj is evolved from conj with above assurance
    (setq nconj (mapcar (f/l (p) 
			     (cond ((and (eq (generic-fnname (car p)) '>)
					 (in (third p) ldvars))
				    (append (list  _<_) (list (third p)) (list (second p))))
				   ((and (eq (generic-fnname (car p)) '>=)
					 (in (third p) ldvars))
				    (append (list  _<=_) (list (third p)) (list (second p))))
				   ((and (eq (generic-fnname (car p)) '<)
					 (in (third p) ldvars))
				    (append (list  _>_) (list (third p)) (list (second p))))
				   ((and (eq (generic-fnname (car p)) '<=)
					 (in (third p) ldvars))
				    (append (list  _>=_) (list (third p)) (list (second p))))
				   (t p)))
			conj))
    ;; 2013-03-26 TT sort indexed predicates
    (setq indxpreds  (sort-idxpreds indxpreds freevars))
    (setq rwconj (rewrite-distance-based-index nconj indxpreds))
    ;; retain conj if nothing change
    (if (equal rwconj nconj) conj rwconj)))

(define-late-tr-rewriter  'euclid 
  'distance-based-index-tester  'distance-based-index-rewriter)
(define-late-tr-rewriter  'minkowski 
  'distance-based-index-tester  'distance-based-index-rewriter)
