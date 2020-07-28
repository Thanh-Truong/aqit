;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2007 Thanh Truong, UDBL
;;; $RCSfile: testsubplan.lsp,v $
;;; $Revision: 1.5 $ $Date: 2007/12/19 21:06:08 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Testing subplan partitioning
;;; =============================================================
;;; $Log: testsubplan.lsp,v $
;;;
;;; =============================================================

(defglobal _sb_)
(defglobal _orgplan_)    

(osql "
create function test0(number)->Number;
set test0(1)=1;
create function test(Number x)->Number
as select test0(x)+1+x+2+x+3;
create function atest(Number x)->Integer 
as select sum(iota(1,x));")    

(setq _sb_ (getselectbody 
	  (getfunctionnamed 'number.test->number)))    

(setq _orgplan_ (selectbody-optpred _sb_))    

(defun splittest(from to _orgplan_)
  (let* ((andl (argsof 'and _orgplan_))
	 (res (splitplan from to andl _sb_))
	 (rsp (car res))
	 (lsp (second res)))
    ;; replace new plan
    (setf (selectbody-optpred _sb_) (join-subplans from to rsp lsp andl))
    (osql "test(1)			;")));; Should always be ((9))     

;;; test all possible plan splittings
(checkequal "plan splitting"
	    ((splittest 1 1 _orgplan_) '((9)))
	    ((splittest 1 2 _orgplan_) '((9)))
	    ((splittest 1 3 _orgplan_) '((9)))
	    ((splittest 1 4 _orgplan_) '((9)))
	    ((splittest 1 5 _orgplan_) '((9)))
	    ((splittest 1 6 _orgplan_) '((9)))
	    ((splittest 2 2 _orgplan_) '((9)))
	    ((splittest 2 3 _orgplan_) '((9)))
	    ((splittest 2 4 _orgplan_) '((9)))
	    ((splittest 2 5 _orgplan_) '((9)))
	    ((splittest 2 6 _orgplan_) '((9)))
	    ((splittest 3 3 _orgplan_) '((9)))
	    ((splittest 3 4 _orgplan_) '((9)))
	    ((splittest 3 5 _orgplan_) '((9)))
	    ((splittest 3 6 _orgplan_) '((9)))
	    ((splittest 4 4 _orgplan_) '((9)))
	    ((splittest 4 5 _orgplan_) '((9)))
	    ((splittest 4 6 _orgplan_) '((9)))
	    ((splittest 5 5 _orgplan_) '((9)))
	    ((splittest 5 6 _orgplan_) '((9)))
	    ((splittest 6 6 _orgplan_) '((9)))
	    )    

;;---------------------------------------------------------------
;; Another test with no argument
;;---------------------------------------------------------------
(osql "
create function test0(Number)->Number;
set test0(1)=1;
create function test1()->Number
as select test0(1)+1+2+3;
")   

(setq _sb_ (getselectbody 
	  (getfunctionnamed 'test1->number)))    

(setq _orgplan_ (selectbody-optpred _sb_))   

(defun splittest(from to _orgplan_)
  (let* ((andl (argsof 'and _orgplan_))
	 (res (splitplan from to andl _sb_))
	 (rsp (car res))
	 (lsp (second res)))
    ;; replace new plan
    (setf (selectbody-optpred _sb_) (join-subplans from to rsp lsp andl))
    (osql "test1()			;")));; Should always be ((9))      

;;; test all possible plan splittings
(checkequal "plan splitting"
	    ((splittest 1 1 _orgplan_) '((7)))
	    ((splittest 1 2 _orgplan_) '((7)))
	    ((splittest 1 3 _orgplan_) '((7)))
	    ((splittest 1 4 _orgplan_) '((7)))
	    ((splittest 2 2 _orgplan_) '((7)))
	    ((splittest 2 3 _orgplan_) '((7)))
	    ((splittest 2 4 _orgplan_) '((7)))
	    ((splittest 3 3 _orgplan_) '((7)))
	    ((splittest 3 4 _orgplan_) '((7)))
	    ((splittest 4 4 _orgplan_) '((7)))
	    )    


(rollback) ;; Undo all AmosQL definitions 
