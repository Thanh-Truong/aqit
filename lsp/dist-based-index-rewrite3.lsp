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
