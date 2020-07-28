(defun date-to-string-without-quote (dt)
  (concat (add-zero (date-year dt))"-"
	    (add-zero (date-month dt))"-"
	    (add-zero (date-day dt)) 
	    " 00:00:00.000"))

(defun timeval-to-string-without-quote (tv )
  (let ((dl (timeval-to-date tv)))
    (concat  (add-zero (aref dl 0)) "-"
	     (add-zero (aref dl 1)) "-"
	     (add-zero (aref dl 2)) " "
	     (add-zero (aref dl 3)) ":"
	     (add-zero (aref dl 4)) ":"
	     (add-zero (aref dl 5)))))
