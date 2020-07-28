;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2011 Thanh Truong, UDBL
;;; $RCSfile: late-tr-rewrite.lsp,v $
;;; $Revision: 1.3 $ $Date: 2013/02/19 05:56:51 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Late TR rewrite rule are similar to TR rewrite
;;; but is applied after 
;;  - all views are expaned
;;; - all equal variables are substituted
;;; - all TR rewrites are applied
;;; =============================================================
;;; $Log: late-tr-rewrite.lsp,v $
;;; Revision 1.3  2013/02/19 05:56:51  thatr500
;;; Limited Search with simple Heuristics
;;;
;;; Revision 1.2  2012/04/16 07:29:38  thatr500
;;; Temporarily, disable cycling 'rewritting' until a fix point.
;;;
;;; Revision 1.1  2011/11/15 09:58:43  thatr500
;;; late TR rewriter
;;;
;;; Revision 1.5  2011/08/17 08:15:29  thatr500
;;; added 'call-late-tr-rewrite-condition'  and 'call-late-tr-rewrite-transformer'
;;;
;;; Revision 1.4  2011/06/11 11:08:13  thatr500
;;; change Euclid predicate to distance predicate. It is general to handle
;;; Euclid and Minkowski now
;;;
;;; Revision 1.3  2011/04/11 08:25:20  thatr500
;;; added smart-ordering-preds to order to-be-rewritten predicates
;;;
;;; Revision 1.2  2011/04/11 07:36:36  thatr500
;;; add freevars into distance-rewriter
;;;
;;; Revision 1.1  2011/04/05 10:59:10  thatr500
;;; Introduced Late TR rewrite
;;;
;;;
;;; =============================================================
;;-------------------------------------------------------------
;; Late TR rewrite
;;-------------------------------------------------------------
(defun define-late-tr-rewriter (fno testfn actionfn)
  "If the a predicate P in conjuncts C has FNO as generic function
   and (TESTFN P C) returns non-NIL value V
   then call (ACTIONFN P C V) to return transformed conjuncts.

  Late TR rewrite rule are similar to TR rewrite but is applied after 
  - all views are expaned
  - all equal variables are substituted
  - all TR rewrites are applied"
  (/putobject (getfunctionnamed fno) 
	      'late-tr-rewriter (cons testfn actionfn)))

(defun get-late-tr-rewriter (fno)
  "Get the late TR rewriter for a function or its generic function"
  (or (getobject fno 'late-tr-rewriter)
      (getobject (generic-function-of fno) 'late-tr-rewriter)))

(defun call-late-tr-rewrite-condition (rw pred rest)
  (funcall rw pred rest))

(defun call-late-tr-rewrite-transformer (rw pred rest cndres freevars)
  (argsof 'and (funcall rw pred rest cndres freevars)))

(defun test-and-rewrite (lpreds freevars) 
  "Apply tester and rewriter if eligible"
  (let* ((rwconj lpreds) (andl lpreds) rw cndres)
    (while (not (atom andl))
      (cond ((and 
	      (listp  andl)
	      (listp  (car andl))
	      (oid-p (caar andl)) ;; is function
	      (setq rw (get-late-tr-rewriter (caar andl)))
	      (setq cndres (call-late-tr-rewrite-condition (car rw) 
						   (car andl) 
						   lpreds)))
	     
	     (setq rwconj (car (call-late-tr-rewrite-transformer 
				(cdr rw)(car andl) 
				lpreds cndres freevars)))
	     (setq andl nil)))
      ;; next predicate
      (setq andl (cdr andl)))	     
    ;; Return 'rewritten' conj
    rwconj))

(defun list-equal? (x y)
  "Two lists are equal regardless their orders"
  (and (eq (length x) (length y))
       (equal (intersection x y) x)
       (equal (intersection y x) y)))
       

(defun call-late-tr-rewriters1 (lpreds freevars) 
  "Apply late-tr-rewriter if any"
  (let* (*after-view-expansion* (org lpreds) new)
    (setq new  (test-and-rewrite org freevars))
    ;;(while (not (list-equal? org new))
    ;;(help 'AAAA)
    ;;(setq org new)
    ;;(setq new  (test-and-rewrite org freevars)))
    new))


;; Make call-late-tr-rewriters0 have the same definition 
;; as call-late-tr-rewriters1
(movd 'call-late-tr-rewriters1 'call-late-tr-rewriters0)