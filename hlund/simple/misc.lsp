(defvar _openfiles_ (make-hash-table :test (function equal)))

(defun slas-open-writefile (filename)
  (if (null (gethash filename _openfiles_)      
	    (setf (gethash filename _openfiles_) (openstream filename "w")))))

(defun slas-get-stream (filename)
  (gethash filename _openfiles_))

(defun slas-close-writefile (filename &optional rem)
  (if (gethash filename _openfiles_)
      (progn
	(closestream (gethash filename _openfiles_))
	(if rem (remhash filename _openfiles_)))))

(defun slas-close-all-writefiles ()
  (maphash (f/l (filename stream)
		(slas-close-writefile filename))
	   _openfiles_)
  (clrhash _openfiles_))


(defun write-to-file (filename string)
  (let ((stream (slas-get-stream filename)))
    (princ string stream)
    (terpri stream)))


(defun flush-to-file (filename)
  (terpri (slas-get-stream filename)))

(defun slas-flush-all-writefiles ()
  (maphash (f/l (filename stream)
		(flush-to-file filename))
	   _openfiles_))


;;-----------------------------------------------------------------------
;; Interface
;;-----------------------------------------------------------------------
(defun slas-open-writefile-+ (fn filename res)
  (osql-result filename (slas-open-writefile filename)))

(defun slas-close-writefile+ (fn filename res)
  (osql-result filename (slas-close-writefile filename)))

(defun slas-close-all-writefiles+ (fn res)
  (osql-result (slas-close-all-writefiles)))

(defun flush-to-file-+ (fn filename res)
  (osql-result filename (flush-to-file filename)))

(defun write-to-file--+ (fn filename string res)
  (osql-result filename string (write-to-file filename string)))

(defun flush-allfiles-+ (fn res)
  (osql-result (slas-flush-all-writefiles)))

(osql "create function slas_openwritefile(Charstring filename)->Boolean as 
       foreign 'slas-open-writefile-+';")

(osql "create function slas_closewritefile(Charstring filename)->Boolean as 
       foreign 'slas-close-writefile+';")

(osql "create function slas_close_all_writefiles()
       ->Boolean as foreign 'slas-close-all-writefiles+';")

(osql "create function slas_flush_tofile(Charstring filename)
       ->Boolean as foreign 'flush-to-file-+';")

(osql "create function slas_write_tofile(Charstring filename, Charstring str)
       ->Boolean as foreign 'write-to-file--+';")


(osql "create function slas_flush_allfiles()
       ->Boolean as foreign 'flush-allfiles-+';")


(defun timevalize-string (str)
  "Convert a timeval to a string"
  (let ((space-pos (string-pos str " ")))
    (concat "|" (substring 0 (1- space-pos) str) "/" 
	    (substring (1+ space-pos) (length str) str) "|")))

(defun timevalize-+ (fno tvstr)
  "Convert a string to a timeval"
  (osql-result tvstr (caar (amos-execute (concat 
					  (timevalize-string tvstr) ";")))))


(osql "create function timevalize(Charstring) -> Timeval
  as foreign 'timevalize-+';")
