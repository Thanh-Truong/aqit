;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2013 Thanh Truong, UDBL
;;; $RCSfile: LISP,v $
;;; $Revision: 1.1 $ $Date: 2006/02/12 20:01:09 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Code to handle subplan
;;; =============================================================
;;; $Log: LISP,v $
;;;
;;; =============================================================

(defun encapsulate-plan (_from _to _orgplan _body)
  "In _orgplan, encapsulate predicates from position _from to 
   position _to as a transient function and produces a new plan
   
   It needs _body which is the body of the function"
  (let* ((sb _body)
	 (andl (argsof 'and o_rgplan))
	 (sp (transform-section-subplan andl _from _to (selectbody-argl sb)
					(selectbody-resl sb))))
    (setf (selectbody-optpred sb) sp)))

(defun compile-function (fno)
  "Realize shippable format fno into _rawworker-job_"
  (setq _rawworker-job_ (internalize-code fno))) 

(defun compile-query-string (str)
  "Realize shippable format str into _rawworker-job_"
  (setq _rawworker-job_ (amos-execute str)))

(defun shippable-sb  (sb)
  "From given sb, return the shippable function "
  (externalize-fndef 
   (predicate-function (selectbody-argl sb)
		       (selectbody-resl sb)
		       (selectbody-pred sb)))) 

(defun shippable-pred  (invars outvars pred)
  "From given pred, return the shippable function out of it "
  (externalize-fndef 
   (predicate-function invars outvars pred))) 

(defun make-shippable-function0 (sb) 
  "Make shippable function from sb"
  (kwote (shippable-sb sb))) 

(defun make-shippable-function1 (invars outvars pred) 
  "Make shippable function from pred"
  (kwote (shippable-pred invars outvars pred))) 

(defun define-job-on-rawworker0 (sb port)
  "Define a function (job) on remote rawworker from sb"
  (send-form (list 'compile-function 
		   (make-shippable-function0 sb)) port)) 

(defun define-job-on-rawworker1 (invars outvars pred port)
  "Define a function(job) on remote rawworker from pred"
  (send-form (list 'compile-function 
		   (make-shippable-function1 invars outvars pred)) port)) 

(defun define-job-on-rawworker2 (str port)
  "Define a function(job) on remote rawworker from a query string"
  (send-form (list 'compile-query-string str) port))

(defun run-job-on-rawworker (args remote_port)
  "Invoke remote transient function rawworker-job. args is an array of arguments"
  (setq *multicastreceive-args* (arraytolist args))
  (send-form (list 'run-remote-transient-function1 args (kwote _amosid_))
	     remote_port))

(defun run-remote-transient-function0 (args reply_peer)
  "This function runs on peer (remote_port) and sends 
   result back to reply_peer. args is vector of arguments" 
  (let ((s (port-socket (port-of-peer reply_peer))))
    (mapfunction _rawworker-job_ args
		  (f/l (row)  (pf row s)))
     (pf0 '*eof* s)))

(defun caller-reply (o)
  (print o))

(defun run-remote-transient-function1 (args reply_peer)
  "This function runs on peer (remote_port) and sends 
   result back to reply_peer. args is vector of arguments" 
  (let* ((reply_port (port-of-peer reply_peer))
	 (s (port-socket reply_port)))
    (mapfunctionres _rawworker-job_ args nil
		 ;; foreach row, send it back to the caller
		 (f/l (row)(send-form  (list 'caller-reply (kwote (car row)))
				       reply_port)))))

