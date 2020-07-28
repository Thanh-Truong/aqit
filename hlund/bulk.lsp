;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun date-to-string-without-quote (dt)
  (concat (add-zero (date-year dt))"-"
	    (add-zero (date-month dt))"-"
	    (add-zero (date-day dt)) 
	    " 00:00:00.000"   
	    ))

(defun timeval-to-string-without-quote (tv )
  (let ((dl (timeval-to-date tv)))
    (concat  (add-zero (aref dl 0)) "-"
	     (add-zero (aref dl 1)) "-"
	     (add-zero (aref dl 2)) " "
	     (add-zero (aref dl 3)) ":"
	     (add-zero (aref dl 4)) ":"
	     (add-zero (aref dl 5)))))

(defun format-and-bulk (bag filename delimiter tablename is_peered)
  (let (start stop filename)    
    (mapbag
     bag
     (f/l (row)
	  (cond ((null start)
		 (setq filename (concat (pwd) "/tmp/"(unique-csv-filename)))
		 (setq *mystream* (openstream filename "w"))
		 (setq start (gettimeofday))
		 (setq stop  (timeval-add-duration start 10.0))))
	  (if (neq row nil)
	      (let* ((a (car row))
		    (len (length a))
		    (size (- (* 2  (length a)) 1))
		    x
		    (i 0))
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
		 (non-blocking-bulk filename tablename is_peered)))

	  )
     )
    ;;(terpri *mystream*)
    (closestream *mystream*)
    (setq *mystream* nil)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
(defun random-string (size)
  "Return a random string (size)"
  (let ((res ""))
    (dotimes (i size)
      (setq res (concat res (int-char (rand 65 90)))))))

(defun non-blocking-bulk (datafile tablename is_peered)
  (let (b (name (mksymbol (random-string 7))))
    (cond ((eq is_peered 'TRUE)
	   (start-program "run" (concat "-s " name))
	   (wait-until-started name)
	   (setq b (open-socket-to name)) 
	   (send-statement (concat " bulk_rdbms('" datafile "','" 
				   tablename "'); quit;") b))
	  (t 
	   (bulk-to-rdbms datafile 
			  (getenv "database")
			  (if (null tablename) (getenv "table")
			    tablename)
			  (getenv "address")
			  (getenv "username")
			  (getenv "password"))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun bulk-to-rdbms (datafile &optional database table address username password) 
  (system (concat "bcp " 
		  database
		  ".."
		  table
		  " in "
		  datafile
		  " -f "
		  table "FMT.xml" 
		  " -S "
		  address 
		  " -U "
		  username
		  " -P "
		  password " -o log.txt")))
				

(defun bulk-to-rdbms-+ (fno datafile tablename r)
  (osql-result datafile
	       tablename
	       (bulk-to-rdbms datafile 
			      (getenv "database")
			      (if (null tablename) (getenv "table")
				tablename)
			      (getenv "address")
			      (getenv "username")
			      (getenv "password"))))


(osql "create function bulk_rdbms(Charstring datafile, Charstring tablename)->Boolean
       as foreign 'bulk-to-rdbms-+';")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun toreal (tv)
  (+ (timeval-sec tv)
     (/ (timeval-usec tv) 1000000.0)))

(defun unique-csv-filename () (concat (toreal (gettimeofday)) ".csv"))
   
(defun format-and-bulk-+ (fno bag tablename is_peered r)
  (format-and-bulk bag  (unique-csv-filename) ";" tablename is_peered))


(osql "create function format_and_bulk(Bag of Vector b, Charstring tablename, Boolean is_peered)->Boolean
       as foreign 'format-and-bulk-+';")
  
  




   