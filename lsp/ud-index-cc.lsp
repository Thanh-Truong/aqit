;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2011 Thanh Truong, UDBL
;;; $RCSfile: ud-index-cc.lsp,v $
;;; $Revision: 1.5 $ $Date: 2015/01/01 21:02:51 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: User defined index on core clustered functions
;;; =============================================================
;;; $Log: ud-index-cc.lsp,v $
;;; Revision 1.5  2015/01/01 21:02:51  torer
;;; removed CTRL-M
;;;
;;; Revision 1.4  2013/10/19 15:40:32  thatr500
;;; Problem: Arbitary random index is chosen as the fist one
;;; encounters
;;; Solution:
;;; Added a heuristic that the choice of index is based on its selectivity
;;; (sorting decreasingly sel / cardinality)
;;;
;;; Revision 1.3  2013/02/19 05:56:51  thatr500
;;; Limited Search with simple Heuristics
;;;
;;; Revision 1.2  2011/12/20 21:17:02  thatr500
;;; reorganized !
;;;
;;; Revision 1.1  2011/11/15 10:00:51  thatr500
;;; User defined index on core cluster function.
;;;
;;;
;;; =============================================================
(defstruct ccindex
 owner
 type
 pos
 cardinality) ;; uniqueness of data values contained in the indexed column
;;------------------------------------------
;; List of indexes on core clustered function
;;------------------------------------------
(defglobal _descr-index-ccfn_ nil 
  "List of indexes on core clustered function")
;;------------------------------------------------------------------------  
(defun add-descr-index-ccfn (fn indextype ccfn pos &optional cardinality)
  (setf _descr-index-ccfn_ 
	(adjoin	(make-ccindex :owner ccfn :type  (mkstring indextype) 
			      :pos pos  ;; assign -10000 if cardinality is
			      ;; not defined
			      :cardinality (if (null cardinality) 
					       -100000 cardinality))
		_descr-index-ccfn_)))

;;------------------------------------------------------------------------  
(defun remove-descr-index-ccfn (fn indextype ccfn pos)
  (setf _descr-index-ccfn_
	(remove (make-ccindex :owner ccfn :type  (mkstring indextype) :pos pos)
		_descr-index-ccfn_)))
;;------------------------------------------------------------------------  
(defun get-descr-index-cc (indextype ccfn)
  "Return pos on ccfn where indextype exits"
  (car (isome _descr-index-ccfn_
	      (f/l (ccindex) 
		   (and		
		    (equal (ccindex-type ccindex) (mkstring indextype))
		    (equal (ccindex-owner ccindex) ccfn))))))

(defun get-ccindex (ccfn)
  "Return ccindex on ccfn where indextype exits"
  (car (isome _descr-index-ccfn_
	      (f/l (ccindex) 
		   (equal (ccindex-owner ccindex) ccfn)))))

;; Indextype CoreclusterFn Index position
(osql "create function add_descr_index_cc(Charstring indextype, Function ccfn, 
                       Number pos) -> Boolean
       as foreign 'add-descr-index-ccfn';")

;; Indextype CoreclusterFn Index position cardinality
(osql "create function add_descr_index_cc(Charstring indextype, Function ccfn, 
                       Number pos, Number cardinality) -> Boolean
       as foreign 'add-descr-index-ccfn';")

(osql "create function  remove_descr_index_cc(Charstring indextype, Function ccfn, Number pos) 
       -> Boolean  as foreign 'remove-descr-index-ccfn';")


