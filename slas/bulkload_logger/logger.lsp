;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun slaslogger (bag filename delimiter tablename &optional bulkload is_peered)
  (let (start stop filename)    
    (mapbag
     bag
     (f/l (row)
	  (help 'me)
	  (cond ((null start)
		 (setq filename (concat (pwd) "/tmp/"(unique-csv-filename)))
		 (setq *mystream* (openstream filename "w"))
		 (setq start (gettimeofday))
		 (setq stop  (timeval-add-duration start 10.0))))
	
	  (if (and (neq row nil)
		   (arrayp (car row)))
	      (let* ((a (car row))
		     (len (length a))
		     (size (- (* 2  (length a)) 1))
		      x (i 0))
		(while (< i size)
		  (if (= (mod i 2) 1)
		      (princ delimiter *mystream*)
		    (progn 
		      (setq x (elt a (/ i 2)))
		      (if (timevalp x)
			 (princ (timeval-to-string-without-quote x) *mystream*)
			(princ x *mystream*))))
		  (setq i (+ i 1)))))
	  ;; flush to output
	  (terpri *mystream*)
	  (cond ((t>= (gettimeofday) stop) 
		 (closestream *mystream*)
		 (setq start nil)
		 (if bulkload
		     (non-blocking-bulk filename tablename is_peered))))
	  
	  )
     )
    ;;(terpri *mystream*)
    (closestream *mystream*)
    (setq *mystream* nil)))

(defun slaslogger-+ (fno bag tablename bulkload is_peered r)
  (slaslogger bag  (unique-csv-filename) ";" tablename (eq bulkload 'TRUE) (eq is_peered 'TRUE)))

;;-------------------------------------------------------------------
;; AmosQL Interface   
;;-------------------------------------------------------------------
(osql "create function slaslogger(Bag of Vector b, 
                                  Charstring tablename, 
                                  Boolean bulkload,
                                  Boolean is_peered)->Boolean
       as foreign 'slaslogger-+';")



