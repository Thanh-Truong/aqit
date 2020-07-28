(checkequal 
 "AQIT group common predicate"
 ((aqit-gcp '(OR (AND p1 p2 p3) (AND p4 p1 p3) (AND p3 p6 p1 p7)))
  '(AND P1 P3 (OR (AND P2) (AND P4) (AND P6 P7))))
 ;; should be the same
 ((aqit-gcp '(OR (AND p2) (AND p4 p1 p3) (AND p3 p6 p1 p7)))
  '(OR (AND P2) (AND P4 P1 P3) (AND P3 P6 P1 P7)))
 ((aqit-gcp '(AND p2 (OR p4 p1 p3) (AND p4 p5)))
  '(AND P2 (OR P4 P1 P3) (AND P4 P5)))
 ((aqit-gcp '(OR p2 (AND p2 p1 p3) (AND p4 p5)))
  '(OR P2 (AND P2 P1 P3) (AND P4 P5)))
 )

(checkequal 
 "Equal list regardless ordering"
 ((equal-lists '(1 2 3) '(3 2 1)) t)
 ((equal-lists '(1 3 2) '(3 1 2)) t)
 ((equal-lists '(OR 1 (AND 2 3) (AND 5 6)) '(OR (AND 5 6) (AND 2 3) 1)) t)
 ((equal-lists '(OR 1 (AND 2 3) (OR 5 6)) '(OR (OR 5 6) (AND 2 3) 1)) t)
 ((equal-lists '(OR 1 (AND 2 3) (OR 5 (AND 6 7))) '(OR (OR (AND 7 6) 5 ) (AND 2 3) 1)) t))

(defun get-ql (fname)
  "Get query plan of fname"
  (if (neq fname nil)
      (let* ((fn (getfunctionnamed fname t)) ;; no error if not exists
	    (rslv (car (resolvents fn))))    ;; the first resolvent by default
	(if rslv 
	    (selectbody-optpred (getselectbody  rslv))))))


(defun query-contain (ql fc)
  "True if query plan ql contains function call fc"  
  (let (lpreds)
    (setq lpreds 
	  (cond ((atom ql))
		((conjunctionp ql) (cdr ql))
		((disjunctionp ql) (cdr ql))
		((listp ql) ql)))
    (some (f/l (p)
	       (if (conjunctionp p)
		   (query-contain (cdr p) fc)
		 (member-of-list fc p))) lpreds)))

		    