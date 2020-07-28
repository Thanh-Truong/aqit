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
(defun splitplan (from to predl sb)
  "From predl (list of predicates),split it into two subplan(s). The former (remote 
    rsp) will be executed remotely, while the latter (local sp) is post-processed"
  (let* ((rsp (section-subplan predl from to (selectbody-argl sb)
			       (selectbody-resl sb))))
    (list rsp (nthcdr to predl)))) 

(defun join-subplans (from to rsp lsp predl)
  "Join remote subplan rsp and local lsp into one plan, which wil be executed
    locally. This function should be called with results of splitplan call"
  (let ((spargl(function-argvars rsp)))
    (andify `(,(andify (firstn (1- from) predl))
	      (call invoke-plan , _invoke-plan_ 
		    , rsp , (length spargl)
		      ,@ spargl ,@ (function-resvars rsp))
	      ,(andify lsp))))) 

(defun encapsulate-plan (_from _to _orgplan _body)
  "In _orgplan, encapsulate predicates from position _from to 
   position _to as a transient function and produces a new plan
   
   It needs _body which is the body of the function"
  (let* ((sb _body)
	 (andl (argsof 'and _orgplan))
	 (sp (transform-section-subplan andl _from _to 
					(selectbody-argl sb)
					(selectbody-resl sb))))
    (setf (selectbody-optpred sb) sp)))
;;----------------------------------------------------------------------
;; Create a transient function from function name
;;----------------------------------------------------------------------
;; make transient function from fn
(defun create-transient-function-+ (fno fn res)
  (let* ((sb (getselectbody (theresolvent fn)))
	 (tsfn  (predicate-function (selectbody-argl sb)
				    (selectbody-resl sb)
				    (selectbody-pred sb))))
    (osql-result fn tsfn))) 

(osql "create function create_transient_function (Function fn)
            ->Function tsfn  as foreign 'create-transient-function-+';")
;;----------------------------------------------------------------------
;; Compile subplan as rawworker job on remote server  
;;----------------------------------------------------------------------
(defun compile-function (fno)
  "Realize shippable format fno into _rawworker-job_"
  (setq _rawworker-job_ (internalize-code fno))) 

(defun compile-query-string (str)
  "Realize shippable format str into _rawworker-job_"
  (setq _rawworker-job_ (amos-execute str)))
;;----------------------------------------------------------------------
;; Pack subplan as shippable object to be sent to remote server  
;;----------------------------------------------------------------------
(defun shippable-pred  (invars outvars pred)
  "From given pred, return the shippable function out of it "
  (externalize-fndef 
   (predicate-function invars outvars pred))) 

(defun make-shippable-function (invars outvars pred) 
  "Make shippable function from pred"
  (kwote (shippable-pred invars outvars pred))) 
;;----------------------------------------------------------------------
;; Calls to define a rawworker job on remote server
;;----------------------------------------------------------------------
(defun define-job-on-rawworker0 (sb port)
  "Define a function (job) on remote rawworker from sb"
  (socket-eval (list 'compile-function 
		     (make-shippable-function 
		      (selectbody-argl sb) (selectbody-resl sb) (selectbody-pred sb))) 
	       (port-socket port))) 

(defun define-job-on-rawworker1 (invars outvars pred port)
  "Define a function(job) on remote rawworker from pred"
  (send-form 
   (list 'compile-function 
	 (make-shippable-function invars outvars pred)) port)) 

(defun define-job-on-rawworker2 (str port)
  "Define a function(job) on remote rawworker from a query string"
  (send-form (list 'compile-query-string str) port))

(defun define-job-on-rawworker3 (transient_fno port)
  "Define a function(job) on remote rawworker from transient_fno"
  (socket-eval (list 'compile-function 
		     (kwote (externalize-fndef transient_fno))) (port-socket port))) 

;;----------------------------------------------------------------------
;; Calls to run a rawworker job on remote server. Result will be printed
;; to sockets
;;----------------------------------------------------------------------
(defun run-job-on-rawworker0 (args remote_port)
  "Invoke remote transient function rawworker-job. args is an 
   array of arguments"
  (send-form (list 'job-reply-to0 args) 
	     (port-of-peer remote_port)))

(defun job-reply-to0 (args)
  "Print to socket of the callee the result stream 
   of applying FN on ARGS"
  (let ((s (port-socket *client-port*)))
    (mapfunctionres _rawworker-job_ args nil
		    ;; foreach row, print to socket
		    (f/l (row)  (pf row s)))
    (pf0 '*eof* s)
    (flush s)))
;;----------------------------------------------------------------------
;; Calls to run a rawworker job on remote server. Result will be shipped
;; back and returned as OSQL-Result
;;----------------------------------------------------------------------
(defun run-job-on-rawworker1 (args remote_port)
  "Invoke remote transient function rawworker-job. args is an array of arguments
   Results will be sent back as AmosQL function results"
  (send-form (list 'reply-to1 (kwote _amosid_)
		   args) (port-of-peer remote_port)))
  
(defun reply-to1 (peer args)
  "Send to PEER return stream from applying _rawworker-job_ on ARGS"
  (let ((port (port-of-peer peer)))
    (mapfunctionres _rawworker-job_
		    args nil 
		    (f/l (row)(send-form 
			       (list 'peer-reply (kwote (car row)))
			       port)))))
    
