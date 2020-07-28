;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2011 Thanh Truong, UDBL
;;; $RCSfile: aqit_utilities.lsp,v $
;;; $Revision: 1.21 $ $Date: 2015/01/01 21:04:14 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Utilities
;;; =============================================================
;;; $Log: aqit_utilities.lsp,v $
;;; Revision 1.21  2015/01/01 21:04:14  torer
;;; (car (subset ...)) -> (car (isome ...))
;;;
;;; Revision 1.20  2014/10/22 08:55:58  thatr500
;;; added heuristic to sort indexedpredicates
;;; (total weight = number of its variables matching freevars)
;;;
;;; Revision 1.19  2014/07/28 16:47:09  thatr500
;;; handled operator binding to index supported operation
;;;
;;; Revision 1.18  2014/07/10 19:21:22  thatr500
;;; - removed dead code
;;; - removed get-identifier function.
;;; - added simpler but better extractkeyvalue function
;;;
;;; Revision 1.17  2014/05/27 16:28:30  thatr500
;;; Added an indexed position argument to extractkeyvalue function.
;;;
;;; Revision 1.16  2013/08/01 13:07:26  thatr500
;;; fixed bug in getidentifier0
;;;
;;; Revision 1.15  2013/04/03 15:18:47  thatr500
;;; ordered the rewrite
;;;
;;; Revision 1.14  2013/02/19 05:56:50  thatr500
;;; Limited Search with simple Heuristics
;;;
;;; Revision 1.13  2012/09/06 08:57:40  thatr500
;;; Added code to simplify a conjunction of predicates when it has invalid intervals
;;; of types:  (a, b) or [a, b] or [a, b) or (a, b] or (infinite, a] , (infinite, a)
;;; Example:
;;; (AND (P X)
;;;      (OR (AND (> X 1)
;;;               (< X 0))
;;;          (AND (> X 0)
;;;               (< X 1))))
;;; results in
;;;   (AND (P X)
;;;        (> X 0
;;;        (< X 1))
;;;
;;; Revision 1.12  2012/06/19 14:56:15  thatr500
;;; write to CSV file
;;;
;;; Revision 1.11  2012/06/12 07:38:51  thatr500
;;; added
;;; - sublist(from to list)
;;; - replace-e(pos x l) --> replace element in list l at position pos by x
;;;
;;; Revision 1.10  2012/05/22 13:51:56  thatr500
;;; removed some code not needed when BigIntegrator is ON
;;;
;;; Revision 1.9  2012/05/21 07:31:21  thatr500
;;; Extracting SQL string from a given function now works with Disjunction
;;;
;;; Revision 1.8  2012/04/27 14:29:24  thatr500
;;; to get fully SQL statement
;;; -  getsql ()
;;; -  getsql (Charstring fname)
;;;
;;; to test a pattern (regular expression) against SQL string of a function.
;;; -  contain-sql-pattern(charstring pattern, Charstring fname)
;;; -  contain-sql-pattern(charstring pattern)
;;;
;;; Revision 1.7  2012/04/16 07:33:01  thatr500
;;; modified 'print-cnd ' to print out debug information
;;;
;;; Revision 1.6  2012/02/24 13:51:28  thatr500
;;; added  'print-aqit-transformation' given fname
;;;
;;; Revision 1.5  2012/01/06 13:18:37  torer
;;; New tuple syntax
;;;
;;; Revision 1.4  2012/01/04 14:53:16  thatr500
;;; get index identifier of a mexi index defined through foreign function
;;;
;;; Revision 1.3  2011/12/24 11:40:05  thatr500
;;; removed code
;;;
;;; Revision 1.2  2011/12/20 21:17:02  thatr500
;;; reorganized !
;;;
;;; Revision 1.1  2011/12/02 13:05:55  thatr500
;;; AQit loading order
;;;
;;; Revision 1.9  2011/11/15 10:06:29  thatr500
;;; 'print-cnd' is to print when a condition holds
;;;
;;; Revision 1.8  2011/11/09 11:12:57  thatr500
;;; *** empty log message ***
;;;
;;; Revision 1.7  2011/10/07 08:06:23  thatr500
;;; to support Euclidean on 1D (not yet)
;;;
;;; Revision 1.6  2011/09/26 13:16:54  thatr500
;;; Added Intersection distance (for histograms)
;;;
;;; Revision 1.5  2011/08/22 08:19:55  thatr500
;;; *** empty log message ***
;;;
;;; Revision 1.4  2011/08/17 08:08:54  thatr500
;;; extractkeyvalue returns a tuple instead of an object
;;;
;;; Revision 1.3  2011/04/11 07:34:25  thatr500
;;; add function to compute index identifier from fn and index-pos
;;;
;;; Revision 1.2  2011/04/05 11:23:28  thatr500
;;; add extractkeyvalue function
;;;
;;; Revision 1.1  2011/03/19 15:13:22  thatr500
;;; separated Mexima and Xtree code
;;;
;;; Revision 1.1  2011/03/04 23:55:56  thatr500
;;; utilities
;;;
;;; =============================================================
(defun insert-after (lst index newelt)
  (push newelt (cdr (nthcdr index lst))) 
  lst)

(defun get-index-rows (pos fno)
  (let* ((ro (get-relation fno)) 
	 (indxl (cond ((null ro) (relation-indexes fno))
		      (t (relation-indexes ro))))
	 (idx (car (isome indxl 
			  (f/l (idx) (eq (index-pos idx) pos))))))
    (if (neq idx nil) (index-rows idx))))

(defun getmexi (pos fno)
  (let ((mx (get-index-rows pos fno)))
    (if (and (neq mx nil) (is-mexi mx))
	mx)))
	 
;; Compute index identifier given index postion
;; and function object having index on
;; This function will be invoked at runtime
;; This is the one and the only place where identifier
;; of external index is computed.
(defun get-index-identifier0 (pos;; position of index
				fno);; function  having index on
  "Get index identifier from given position on given function"
  (let* ((mxff (get-index-rows pos fno)))
    (if (and (neq mxff nil)
	     (not (is-mexi mxff)))
	(mexi-foreign-getid mxff))))

;; Question 
;;    Why the C foreign function takes (index position, function) as
;;    input parameters to compute index identifier which possibly can
;;    be computed in excution plan.?
;; Answer 
;;    If such index identifier (id) appears in excution plan, it makes 
;;    hard-wired execution plan since for some reasons, the id value 
;;    can be changed.i.e: a function is redefined
;;
;;    Therefore, it should be computed at runtime by the foreign function.
;; Compute index identifier


(defun intersection_distancefn (fno v1 v2 dist)
  ;; Interection distance which is mostly used in
  ;; comparing histograms (vectors)
  (let* ((dim (min (length v1) (length v2)))
	 (sum 0))
    (dotimes (i dim) 
      (setq sum (+ sum (min (elt v1 i) (elt v2 i)))))
    (setq sum (- 1 (/ (* sum 1.0) dim))) 	
    (osql-result v1 v2 sum)))

(osql "
create function intersection_distance(Vector of Number v1, Vector of Number v2)->Number 
 as foreign 'intersection_distancefn';")

(defun inter_distfn (fno v1 v2 dist)
  ;; Interection distance which is mostly used in
  ;; comparing histograms (vectors)
  (let* ((dim (min (length v1) (length v2)))
	 (sum 0))
    (dotimes (i dim) 
      (setq sum (+ sum (min (elt v1 i) (elt v2 i)))))
    (osql-result v1 v2 sum)))

(osql "
 create function inter_dist(Vector of Number v1, Vector of Number v2)->Number 
 as foreign 'inter_distfn';")  

;;-------------------------------------------------------------------
;; Predicate utilities
;;-------------------------------------------------------------------
(defun arithmetic-p (pred)
  ;; TRUE if p is an arithmetic predicate (plus, minus, times, div)
  (in (predicate-operator pred)  
      (list _number-plus_ _number-minus_ _number-times_ _number-div_)))

(defun predicate-plus-p (pred)
  (and (predicate-p pred)
       (eq (predicate-operator pred) _number-plus_)))

(defun predicate-minus-p (pred)
  (and (predicate-p pred)
       (eq (predicate-operator pred) _number-minus_)))

(defun predicate-times-p (pred)
  (and (predicate-p pred)
       (eq (predicate-operator pred) _number-times_)))

(defun predicate-div-p (pred)
  (and (predicate-p pred)
       (eq (predicate-operator pred) _number-div_)))

(defun intersection-args (pred1 pred2)
  "Intersection between arguments of two given predicates"
  (intersection (predicate-arguments pred1)
		(predicate-arguments pred2)))

  
;;==============================================================
;; Spatial global variables
;;==============================================================

(defglobal _euclid_ 
  (getfunctionnamed 'VECTOR-NUMBER.VECTOR-NUMBER.EUCLID->NUMBER)
  "The resolvent euclid(Vector, Vector)->Number")

(defglobal _manhattan_ 
  (getfunctionnamed 'VECTOR-NUMBER.VECTOR-NUMBER.MANHATTAN->NUMBER)
  "The resolvent manhattan(Vector, Vector)->Number")

(defglobal _intersection_distance_ 
  (getfunctionnamed 'VECTOR-NUMBER.VECTOR-NUMBER.INTERSECTION_DISTANCE->NUMBER)
  "The resolvent intersection distance(Vector, Vector)->Number")

(defglobal _minkowski_ 
  (getfunctionnamed 'VECTOR-NUMBER.VECTOR-NUMBER.NUMBER.MINKOWSKI->REAL)
  "The resolvent minkowski(Vector, Vector, Number)->Real")


(defglobal _distance-predicates_ (list _euclid_ _manhattan_ _intersection_distance_
				        _minkowski_)
  "List of supported distance preidcates")


(defun sort-idxpreds (idxpreds idxtype freevars)
  (let (idxes idx_ps hweight) 
    ;; collect all pairs of (idx, pred, var ) of the same types
    (mapc (f/l (p) 
	       ;; collect indexes of the same type
	       (setq idxes (indexes-of-kind (car p) idxtype t))
	       ;; build list of triple (idx, p, v)
	       (mapc (f/l (idx)
			  (setq idx_ps (cons ;; triple 
					(list idx p (nth (+ 1 (index-pos idx)) p))
					idx_ps)))
		     idxes))
	  idxpreds)
    ;; calculate weights
    (setq hweight  (make-hash-table :test (function equal)))
    (mapc (f/l (i)
	       (let* ((p (second i))
		      (idxed_v (third i))
		      ;; first chance
		      (pos (car (list-positions idxed_v freevars)))
		      othervar weight oweight)
		 ;;(help 'you)
		 (if (null pos) ;; no indexed variable out
		     (progn 
		       (setq othervar (car (intersection (predicate-vars p) freevars)))
		       ;; second chance
		       (setq pos (car (list-positions othervar freevars)))))
		 
		 ;; increment pos by 1 to avoid 0 and nil
		 (setq weight (if pos (* (+ pos 1.5) (+ pos 1.5)) 1))
		 (setq oweight (gethash p hweight))
		 ;; accumulate the weight
		 (puthash p hweight (+ (if oweight oweight 0) weight))))
	  idx_ps)
    
    (sort idxpreds
	  (f/l (a b)
	       (let ((wa (gethash a hweight))
		     (wb (gethash b hweight)))
		 (if (= wa 1) (setq wa 10000))
		 (if (= wb 1) (setq wb 10000))
		 (> wa wb)))))) 

;; Given an index entry (multiple, unique-ness), return
;; a set of columns = row
(create-function extractkeyvalue((object)) ((vector))
       as foreign (extractkeyvaluefn))

(defun extractkeyvaluefn (fn entry row)
  "Given an index entry (multiple, unique-ness), return
   a set of columns"
  (if (arrayp entry)	
      (osql-result entry entry)
    (dolist (r entry)
      (osql-result entry r))))

;; Given an index entry (multiple, unique-ness), return
;; a set of columns = row
(create-function extractkeyvalue0((object) (number )) ((vector))
       as foreign (extractkeyvalue0fn))

(defun -cal-return-pos- (len pos)
  (if (= len 2)
      (if (= 0 pos) 1
	(if (= 1 pos) 0))))

(defun extractkeyvalue0fn (fn entry pos row)
  "Given an index entry (multiple, unique-ness), return
   a set of columns"
  (let (apos)
    (cond ((arrayp entry)
	   (setq apos  (-cal-return-pos- (length entry) pos))
	   (if apos (osql-result entry pos (elt entry apos))
	     (osql-result entry pos entry)))
	  (t 
	   (dolist (r entry)
	     (setq apos  (-cal-return-pos- (length r) pos))
	     (if apos (osql-result entry pos (elt r apos))
	       (osql-result entry pos r)))))))
	   
