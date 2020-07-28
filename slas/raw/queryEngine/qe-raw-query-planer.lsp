;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2013 Thanh Truong, UDBL
;;; $RCSfile: LISP,v $
;;; $Revision: 1.1 $ $Date: 2006/02/12 20:01:09 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Query Engine Place Holder only... Not 
;;; intended to replace the compile_phase2
;;; =============================================================
;;; $Log: LISP,v $
;;;
;;; =============================================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Global variables 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defglobal _spawn-all-rawworkers_
  (getfunctionnamed 
   'LOGDATASTREAM.SPAWN_ALL_RAWWORKERS->VECTOR-RAWWORKERREMOTE)
  "spawn RawWorker(s) on chunks")  

;;(osql "costhint('LOGDATASTREAM.SPAWN_ALL_RAWWORKERS->VECTOR-RAWWORKERREMOTE','bf',{10,100});") 

(defglobal _multicast-receive-chunks_ 
  (getfunctionnamed 
   'VECTOR-RAWWORKERREMOTE.CHARSTRING.NUMBER.MULTICASTRECEIVECHUNKS->OBJECT)
  "multicast receive from chunks with fanout") 

(defglobal _mapsubquery-on-chunks_ 
  (getfunctionnamed 
   'VECTOR-RAWWORKERREMOTE.OBJECT.VECTOR.NUMBER.MAPSUBQUERYONCHUNKS->OBJECT)
  "mapsubquery on chunks with fanout")

(osql "costhint('VECTOR-RAWWORKERREMOTE.OBJECT.VECTOR.NUMBER.MAPSUBQUERYONCHUNKS->OBJECT','bbbbf',{10,10000});") 

(defglobal _rawworker-job_ nil 
  "Job (function) that a RawWorker needs to complete")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compiler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun apply-rewrites-on-raw-query? ()
  "Test if rewrites for raw queries should be invoked. 
   It happens only on  slasraw-query processor not rawworker"
  (and (eq _rawworker_ nil)
       (or *enable-raw-query-parallel*
	   *enable-raw-query-sequential*
	   (and *enable-raw-subquery-parallel*
		(neq *enable-raw-subquery-parallel* 'SKIP)))))

(defvar *indexrewriterules*) ;; mexima rule cache

(defun compile_phase2 (pred resl argl quantl quantdecl fno sb)
  "Query simplification, view expansion, normalization, optimization"
  ;; The dynamicaly bound *bindings* and *locals* must be set before 
  ;; invoking this function
  (let* (*coerced_input* 
	 *extendedResult* *extendedVars*
	 (*after-view-expansion* nil)
	 (*indexrewriterules* t);; empty mexima rule cache
	 (bndl (append argl resl (union quantl *locals*))))
    (setq pred (andify (compilepredicate pred fno)));;Generate TR pred
    (check-unbound-var quantdecl pred nil)
    (if _save-intermediates_ (setf (selectbody-unoptimized sb) pred)) 
    (setq pred (rewrite-before-view-expansion pred sb))
    (setf (selectbody-orgpred sb) pred)
    (update-locals sb quantl)
    (update-locals sb *locals*)    
    
    (setq pred (expand-predicate pred nil));; View expansion
    (if _save-intermediates_ (setf (selectbody-expanded sb) pred))
    (setq *after-view-expansion* t)    
    
    (setq pred (rewrite-after-view-expansion pred sb))
    (if _save-intermediates_ 
	(setf (selectbody-expanded-simplified sb) pred))  
    (cond (*enable-aqit*
	   (setq pred (aqit-fixpoint pred))
	   (if _save-intermediates_ (setf (selectbody-aqit sb) pred))))  
    ;; Normalize to DNF
    (if *use-dnf* (setq pred (transformpredicate pred)))
    (if _save-intermediates_ (setf (selectbody-normalized sb) pred))      
    (setq pred (rewrite-after-normalization pred sb))
    (setf (selectbody-pred sb) (if pred (copy-tree pred) 'TRUE))    
    
    ;; Only call raw-query-compile if this is slasraw-query processor
    (if (apply-rewrites-on-raw-query?)
	(setq pred (raw-query-compile pred sb)))
    
    (update-locals sb *locals*)
    (cond (*skip-optimization* nil)
	  (t      
	   ;;To expand the templates of the input variables
	   ;;These are not expanded because 
	   ;;   they should be so in selectbody-pred
	   (setq pred (process_typechecks pred sb argl resl nil))  
	   ;; Coercion and cost-based optimization  
	   (optimize-pred pred sb fno)
	   ;;(help 'me)
	   (cond ((not (expand-views?))    
		  (setf (selectbody-delpred sb);;Update template
			(create-delpred (selectbody-optpred sb)))
		  sb)))))) 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Rewriter for Raw CC functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun rewrite-rawcc-test (p c)
  ;; Return T if fno is marked as LoggedDataStream
  (if (and (apply-rewrites-on-raw-query?)
	   (predicate-p p)
	   (not (compound-p p)))
      (getobject (car p) 'loggeddatastream)))  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun rewrite-rawcc-action (fo c lds) c)
  ;; - lds (LogDataStream) object was returned from 
  ;;   (rewrite-rawcc-test fno c)
  ;; - c conjunction  ;; - fno predicate (equivalent to core cluster function)  
  ;; What will happen?  
  ;; Replace xxxx_MEASURESB_RAWCC with new operator searchLoggedStream
  ;; This operator at run-time will spawn several peers (equivalent to
  ;; # of chunks) to do the search. The results are streamed back and
  ;; returned. 
(defun rewrite-rawcc-fn (fn fno r)
  (if (and (apply-rewrites-on-raw-query?))
      (osql-result fno (define-tr-rewriter fn 
			 'rewrite-rawcc-test 
			 'rewrite-rawcc-action))
    (osql-result fno nil)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-query-compile (pred sb)
  "Raw query compile"
  (let* ((rawccs 
	  (subset 
	   (cdr pred)  (f/l (p) 
			    (cond ((and (predicate-p p)
					(not (compound-p p))
					(getobject (car p)  'loggeddatastream))
				   p))))))
    ;; OBS! The order does matter here. 
    (cond ((and rawccs *enable-raw-subquery-parallel*)
	   (raw-subquery-parallel-planer rawccs pred sb))
	  ((and rawccs *enable-raw-query-parallel*)
	   (raw-query-parallel-planer rawccs pred sb))
	  ((and rawccs *enable-raw-query-sequential*)
	   (raw-query-sequential-planer rawccs pred sb))
	  (t pred))))   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-get-decode-funcall (rawcc)
  ;; input a racc function call, return its decode function call
  (let* ((name (getobject (car rawcc) 'name))
	 (parts (string-explode (mkstring name) "->"))
	 (fname_input (car parts))
	 (res_output (cadr parts)) ;; remove "_RAWCC"
	 (fname (substring 0 (- (length fname_input) 7) fname_input))
	 (decode_fname (concat fname "._DECODE_->" 
			       (substring 1 (- (length res_output) 1)
					  res_output))))
    (getfunctionnamed (mksymbol decode_fname))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-get-rowtocolumns-funcall (rawcc type)
  ;;#[OID 2948 "VECTOR.LOGFILE_MEASURESB_ROWTOCOLUMNS
  ;;  ->NUMBER.NUMBER.NUMBER.NUMBER.NUMBER"
  (let* ((name (getobject (car rawcc) 'name))
	 (parts (string-explode (mkstring name) "->"))
	 (fname_input (car parts))
	 (res_output (cadr parts)) ;; remove "_RAWCC"
	 (fname (substring 0 (- (length fname_input) 7) fname_input))
	 (rowtocolumns_fname 
	  (concat type "." fname "_ROWTOCOLUMNS->" 
		  (substring 1 (- (length res_output) 1) res_output))))
    (getfunctionnamed (mksymbol rowtocolumns_fname)))) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-remove-decode-funcall (rawcc preds)
  ;; remove decode funcall of rawcc
  (let ((decodefncall (raw-get-decode-funcall rawcc))
	(npreds preds))
    (dolist (p preds)
      (if (equal (car p) decodefncall)
	  (setq npreds (remove p preds))))
    npreds))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parallel search on chunks with hardcode fullscan job
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-query-parallel-planer (rawccs pred sb)
  "Parallel search on chunks with hardcode fullscan job"
  (let ((preds (cdr pred)) (i 0) (npreds (cdr pred)))
    (dolist (p preds)
      (if (member p rawccs)
	  (let ((lds (getobject (car p) 'loggeddatastream)) 	 
		;; Generate variables
		(rawworkerremote_v 
		 (dt_genvar (car (gettypesnamed (list 'VECTOR)))))
		;; output variables
		(outvars (predicate-vars p))
		(row_v (dt_genvar (car (gettypesnamed (list 'VECTOR))))))   
	    ;; remove predicate p, decode call
	    (setq npreds (remove p npreds))
	    (setq npreds (raw-remove-decode-funcall p npreds))
	    ;; inject some predicates to call multicast on chunks
	    (setq npreds (adjoin (list _spawn-all-rawworkers_ lds 
				       rawworkerremote_v) npreds)) 
	    (setq npreds (adjoin (list _multicast-receive-chunks_ 
				       rawworkerremote_v "rawworker_fullscan_chunk" 
				       (raw-lds-get-numChunks lds) row_v) npreds)) 
	    ;; vector row to columns
	    (setq npreds (adjoin (append2 (list 
					   ;;(raw-get-rowtocolumns-funcall p "VECTOR"))
					   _vector-constructor_)
					  (adjoin row_v outvars))
				 npreds))        
	    
	    )))
    (andify npreds)))           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sequential search on chunks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-query-sequential-planer (rawccs pred sb)
  "Sequential search on chunks"
  (let ((preds (cdr pred)) (i 0) (npreds (cdr pred)))
    (dolist (p preds)
      (if (member p rawccs)
	  (let ((lds  (getobject (car p) 'loggeddatastream))
		(outvars (predicate-vars p))
		(row_v (dt_genvar (car (gettypesnamed (list 'VECTOR)))))
		(rfp_v (dt_genvar (car (gettypesnamed (list 'CHARSTRING)))))
		(mfp_v (dt_genvar (car (gettypesnamed (list 'CHARSTRING))))))       
	    ;; remove predicate p, decode call
	    (setq npreds (remove p npreds))
	    (setq npreds (raw-remove-decode-funcall p npreds))
	    ;; inject sequential scan on chunks
	    (setq npreds 
		  (adjoin (list (getfunctionnamed 
				 'LOGDATASTREAM.GETCHUNKS->CHARSTRING.CHARSTRING)
				lds rfp_v mfp_v) npreds))
	    (setq npreds 
		  (adjoin (list (getfunctionnamed 
				 'CHARSTRING.NUMBER.FULLSCAN_CHUNK->OBJECT)
				rfp_v (raw-lds-get-cols lds) row_v) npreds))
	    ;; vector row to columns
	    (setq npreds (adjoin (append2 (list 
					   ;;(raw-get-rowtocolumns-funcall p "VECTOR"))
					   _vector-constructor_)
					  (adjoin row_v outvars))
				 npreds)))))
    (andify npreds)))
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parallel search on chunks with subplan job
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun raw-subquery-parallel-planer (rawccs pred sb)
  "Parallel search on chunks with subplan job"
  (let ((preds (cdr pred)) (i 0) (npreds (cdr pred)))
    (dolist (p preds)
      (if (member p rawccs)
	  (let* ((lds (getobject (car p) 'loggeddatastream)) 	 
		;; Generate variables
		 (rawworkerremote_v 
		  (dt_genvar (car (gettypesnamed (list 'VECTOR)))))
		 ;; output variables
		 (outvars (predicate-vars p))
		 (row_v (dt_genvar (car (gettypesnamed (list 'VECTOR)))))
		 (orgplan (selectbody-optpred sb))
		 (andl (argsof 'and orgplan))
		 subplans)
	    ;; remove predicate p, decode call
	    (setq npreds nil)
	    (setq npreds (remove p npreds))
	    (setq npreds (raw-remove-decode-funcall p npreds))
	    ;; create subplan.            
	    ;; It can lead to infinite loop as internally, the create-subplan
	    ;; will call compile-query, which calls compile_phase2...           
	    ;; To avoid that, I simply disable/enable *enable-raw-subquery-parallel*
	    (setq *enable-raw-subquery-parallel* 'SKIP)
	    (setq subplans (splitplan 1 (length preds) preds sb))
	    (setq *enable-raw-subquery-parallel* t)
	    ;;(help 'halfway)
	    ;; inject some predicates to call multicast on chunks
	    (setq npreds (adjoin (list _spawn-all-rawworkers_ lds 
				       rawworkerremote_v) npreds)) 
	    (setq npreds (adjoin (list  _mapsubquery-on-chunks_ 
					rawworkerremote_v 
					(first subplans)
					(vector) ;; argument !!!!! 2014-03-11 Arg!! 
					(raw-lds-get-numChunks lds) row_v) npreds)) 
	    ;; vector row to columns
	    (setq npreds (adjoin (append2 (list 
					   (raw-get-rowtocolumns-funcall p "OBJECT"))
					  ;;_tuple-constructor_)
					  (adjoin row_v outvars))
				 npreds))                     

	    ))) 
    ;;(help 'finally)
    (andify (reverse npreds))))      

