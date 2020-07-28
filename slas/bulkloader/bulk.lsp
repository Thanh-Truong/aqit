(defun random-string (size)
  "Return a random string (size)"
  (let ((res ""))
    (dotimes (i size)
      (setq res (concat res (int-char (rand 65 90)))))))

(defun toreal (tv)
  (+ (timeval-sec tv)
     (/ (timeval-usec tv) 1000000.0)))

(defun unique-csv-filename () (concat (toreal (gettimeofday)) ".csv"))
;;-------------------------------------------------------------------   
(defun non-blocking-bulk (datafile tablename &optional is_peered)
  (let (b (name (mksymbol (random-string 7))))
    (cond (is_peered
	   (start-program "run" (concat "-s " name))
	   (wait-until-started name)
	   (setq b (open-socket-to name)) 
	   ;; send AmosQL query to do the job
	   (send-statement (concat " bulk_rdbms('" datafile "','" 
				   tablename "'); quit;") b))
	  (t 
	   ;; make a system call
	   (bulk-to-rdbms datafile 
			  (getenv "database")
			  (if (null tablename) (getenv "table")
			    tablename)
			  (getenv "address")
			  (getenv "username")
			  (getenv "password"))))))

(defun bulk-to-rdbms (datafile &optional database table address username password) 
  (system (concat "bcp "  database  ".."  table  " in "  datafile  " -f "  table "FMT.xml" 
		  " -S "  address   " -U " username  " -P " password " -o log.txt")))
				
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
;;-------------------------------------------------------------------
;; AmosQL Interface   
;;-------------------------------------------------------------------
(osql "create function bulk_rdbms(Charstring datafile, Charstring tablename)->Boolean
       as foreign 'bulk-to-rdbms-+';")




   