(defun raw-full-scanfn (fn m s bt et mv)
  (raw-full-scan "measuredB.bin" (mkstring 5)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Basic OPEN SCAN, NEXT, CLOSE SCAN
;; The AmosQL functions are in raw_scan.osql
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SCAN ALL
(defun raw-full-scan (logfile cols)
  (let ((s (open-log-file-scan logfile cols))
	i)
    (while (not (scan-eos s))
      (setq i (car (scan-nextrow s)))
      (if (arrayp i)		 
	  (osql-result 
	   (elt i 0) (elt i 1)
	   (elt i 3) (elt i 2)
	   ;; there is some mistake in the file.    
	   ;;I have to  re-map column 2 to et and column 3 to bt
	   (elt i 4))))))   

;; OPEN SCAN
(defun open-log-file-scan (logfile cols)
  ;; When a node is RawWorker, it is associated
  ;; with a partition. Thefore,raw-full-scan must determine the partition at
  ;; run-time
  (let ((rlogfile (if _rawworker_ (rawworker-datafile _rawworker_)
		    logfile)))
    (print (concat _amosid_ " reading data at " rlogfile))
    (open-query-scan (eval `(concat "readblogfile('" ,rlogfile "'," ,cols ");")))))

(defun open-log-file-scanfn (fn logfile cols s)
  (osql-result logfile cols (open-log-file-scan logfile cols)))

;; CLOSE SCAN
(defun close-log-file-scanfn (fn s r)
  (osql-result s (scan-terminate s)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some functions to generate full scan on a single log file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmacro raw-fname (mappedRelation)
  ;; generate raw-log-file-XXXX where XXXX is a mapped relation
  `(let ((fname (mksymbol (concat "raw-fullscan-nochunks-" , mappedRelation))))
     fname))  
(defmacro  raw-arguments (columnNames)
  ;; generate arguments of RawCC XXXX 
  `(let ((arguments (mksymbol  ,columnNames)))
     arguments))   

(defmacro  raw-datafile (mappedRelation)
  ;; Assume a LoggedDataStream has only single chunk.
  ;; It generates XXXX.bin
  `(let ((dtf (concat ,mappedRelation ".bin")))
     dtf))

(defun mark-it-rawccfn (fn o lds res)
  ;; When defning a log data stream X, its RawCC (raw core cluster)
  ;; will be marked as LoggedDataStream
  (osql-result o (putobject o 'loggeddatastream lds)))    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; These following functions will be used in RAW QUERY ENGINE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-generate-fullscan-no-chunks (fn columnNames mappedRelation cols)
  ;; This assumes entire data in one big file
  (let ((fname     (raw-fname mappedRelation))
	(arguments (raw-arguments columnNames))
	;; This is a default datafile one. When a node is RawWorker, it is associated
	;; with a partition. Thefore,raw-full-scan must determine the partition at
	;; run-time
	(dtf   (raw-datafile mappedRelation)))
    (eval `(defun ,fname (fn ,arguments)  
	     (raw-full-scan ,dtf   ,cols)))
    (osql-result columnNames mappedRelation cols)))   

(defmacro raw-mappedRelation-RowToColumns (mappedRelation type)
  ;; return mappedRelation symbol
  `(let ((fname (mksymbol  (concat ,mappedRelation 
				   (if (eq ,type 'VECTOR)
				       "_vRowToColumnsfn"
				     ;; else TUPLE
				     "_tRowToColumnsfn")))))
     fname)) 

(defun raw-generateImplRowToColumns (fn lds r)
  (let* ((mappedRelation (caar (getfunction 'mappedRelation (list lds))))
	 (vfname (raw-mappedRelation-RowToColumns mappedRelation 'VECTOR))
	 (tfname (raw-mappedRelation-RowToColumns mappedRelation 'TUPLE))
	 (colNames (arraytolist (caar (getfunction 'columnNames (list lds)))))
	 (cols (caar (getfunction 'cols (list lds))))
	 (args "") argssym 
	 returnforms)
    ;; build args
    (dolist (c colNames)
      (setq args (concat args c " ")))
    (setq argssym (mksymbol args)) 
    ;; one Lisp function to convert from vector to columns
    (setq returnforms (vector-to-columns cols))
    (eval-forms (mkstring `(defun ,vfname (fn v ,argssym)
		       (osql-reSult v ,returnforms))))

    ;; one Lisp function to convert from tuple to columns
    (setq returnforms (tuple-to-columns cols))
    (eval-forms (mkstring `(defun ,tfname (fn v ,argssym)
		       (osql-reSult v ,returnforms))))

    (osql-result lds t)))    

 (defun vector-to-columns (cols)
   (let ((i 0) (returnform ""))
     (while (< i cols)
       (setq returnform (concat returnform "(elt v " i ") "))
       (1++ i))
     (mksymbol returnform)))

 (defun tuple-to-columns (cols)
   (let ((i 0) (returnform ""))
     (while (< i cols)
       (setq returnform (concat returnform "(nth " i " v) "))
       (1++ i))
     (mksymbol returnform)))
