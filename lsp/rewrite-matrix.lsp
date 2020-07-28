;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2011 Thanh Truong, UDBL
;;; $RCSfile: rewrite-matrix.lsp,v $
;;; $Revision: 1.5 $ $Date: 2015/01/01 21:06:04 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description:  Rewrite-matrix to define which to be rewritten 
;;;  for distance-based index
;;; =============================================================
;;; $Log: rewrite-matrix.lsp,v $
;;; Revision 1.5  2015/01/01 21:06:04  torer
;;; (car (subset ...)) -> (car (isome ..)) or (assoc ...)
;;;
;;; Revision 1.4  2014/07/28 16:47:10  thatr500
;;; handled operator binding to index supported operation
;;;
;;; Revision 1.3  2012/02/24 13:52:55  thatr500
;;; commented !
;;;
;;; Revision 1.2  2012/01/17 16:10:32  thatr500
;;; renamed variable _spatial-indexes_ to _aqit-supported-indexes_
;;;
;;; Revision 1.1  2011/11/15 10:01:50  thatr500
;;; Matrix of indextypes and theirs supported AM(s)
;;;
;;; Revision 1.3  2011/05/04 08:26:08  thatr500
;;; added rewrite rule for KNN operator by add_knn_rewrite_rule.
;;;
;;; Revision 1.2  2011/04/11 07:35:25  thatr500
;;; changed stored matrix from hashtable to list
;;;
;;; Revision 1.1  2011/04/05 11:05:14  thatr500
;;; Rewrite-matrix to define which to be rewritten for space partioning index
;;;
;;; =============================================================

;;------------------------------------------
;; Rewrite matrix for distance search
;;------------------------------------------
(defglobal _aqit-matrix-rewrite-rules_ nil 
  "A matrix of AQIT rewrite rules: 
   A rule = (an index type, supported distance function,  and its associated access method)")
;;------------------------------------------------------------------------  
(defun add-index-rewrite-rulefn (fn indextype distancefn amfn)
  "Add to _aqit-matrix-rewrite-rules_ a rule:
  Rewrite distancefn on a stored function having indextype to 
  access method function (amfn)"
  ;; Accumulate indextype
  (setq _aqit-supported-indexes_ (adjoin (mksymbol1 indextype) _aqit-supported-indexes_))
  ;; Add one entry to the rewrite matrix
  (setf _aqit-matrix-rewrite-rules_ 
	(adjoin (list indextype distancefn amfn) _aqit-matrix-rewrite-rules_)))

;;------------------------------------------------------------------------  
(defun remove-index-rewrite-rulefn (fn indextype distancefn amfn)
  "Remove from _aqit-matrix-rewrite-rules_ a rule:
  Rewrite distancefn on a stored function having indextype to 
  access method function (amfn)"
  (setf _aqit-matrix-rewrite-rules_ 
	(remove (list indextype distancefn amfn) _aqit-matrix-rewrite-rules_)))
;;------------------------------------------------------------------------  
(defun get-amfn (indextype distancefn)
  "Rewrite distancefn on a stored function having indextype to 
   access method function (amfn)"
  (third (car (isome _aqit-matrix-rewrite-rules_ 
		     (f/l (l) 
			  (and		
			   (equal (first l) (mkstring indextype))
			   ;;(help 'LL)
			   (eq (second l) distancefn)))))))
  

(osql "create function add_index_rewrite_rule(Charstring indextype, 
        Function distfn, Function amfn) -> Boolean
       as foreign 'add-index-rewrite-rulefn';")

(osql "create function remove_index_rewrite_rule(Charstring indextype, 
        Function distfn, Function amfn) -> Boolean
       as foreign 'remove-index-rewrite-rulefn';")
;;------------------------------------------
;;------------------------------------------
;;------------------------------------------
;;------------------------------------------
;;------------------------------------------
;; Rewrite matrix for KNN
;;------------------------------------------
;;------------------------------------------
;;------------------------------------------
;;------------------------------------------
;;------------------------------------------
(defglobal _knn-rewrite-matrix_ nil 
  "List of AQIT supported KNN indexes")

(defun add-knn-rewrite-rulefn (fn indextype amfn)
  "Add to _knn-rewrite-matrix_ a rule:
  Rewrite knn operator on a stored function having indextype to 
  access method function (amfn)"
  (setq _aqit-supported-indexes_ (adjoin (mksymbol1 indextype) _aqit-supported-indexes_))
  (setf _knn-rewrite-matrix_ 
	(adjoin (list indextype amfn) _knn-rewrite-matrix_)))

;;------------------------------------------------------------------------  
(defun remove-knn-rewrite-rulefn (fn indextype amfn)
  "Remove from _aqit-matrix-rewrite-rules_ a rule"
  (setf _knn-rewrite-matrix_ 
	(remove (list indextype  amfn) _knn-rewrite-matrix_)))
;;------------------------------------------------------------------------  

(defun get-knnamfn (indextype)
  (second (assoc (mkstring indextype) _knn-rewrite-matrix_)))
  

(quote (osql "create function add_knn_rewrite_rule(Charstring indextype, 
        Charstring amfn) -> Boolean
       as foreign 'add-knn-rewrite-rulefn';"))

(quote (osql "create function remove_knn_rewrite_rule(Charstring indextype, 
        Charstring amfn) -> Boolean
        as foreign 'remove-knn-rewrite-rulefn';"))
