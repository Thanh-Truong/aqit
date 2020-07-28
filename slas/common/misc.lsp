(defmacro set-realtime-timer (form period)
  "Set REALTIME timer. A real-time timer that counts elapsed time.  
   This timer sends a SIGALRM signal to the process when it expires"
  `(slas-set-timer ,form ,period 1)) 

(defmacro set-virtual-timer (form period)
  "Set VIRTUAL timer. A virtual timer that counts processor time used by the process. 
   This timer sends a SIGVTALRM signal to the process when it expires."
  `(slas-set-timer ,form ,period 2))

(defmacro set-profiling-timer (form period)
  "Set PROFILING timer. A profiling timer that counts both processor time used by the process, 
   and processor time spent in system calls on behalf of the process. 
   This timer sends a SIGPROF signal to the process when it expires. This timer is useful 
   for profiling in interpreters. The interval timer mechanism does not have the fine granularity 
   necessary for profiling native code."
  `(slas-set-timer ,form ,period 3))


;;; To reset a timer, one needs to specify nil (form) and 0 (period). For example:
;;; (set-realtime-timer nil 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun get-rightmost-slash (filepath)
  "Return the right most slash in the given filepath"
  (let* ((len (length filepath))
	 (env (system-environment))
	 (slash (cond ((equal env "VisualC++") "\\")
			  ((member env '("Unix" "Apple")) "/")))
	 (last_slash (string-rightpos filepath slash)))
    last_slash))

(defun getdir-from-filepath (filepath)
  "Get directory path of the given filepath"
  (let* ((last_slash (get-rightmost-slash filepath)))
    (if last_slash (substring 0 last_slash filepath))))

(defun getfilename-from-filepath (filepath)
  "Get filename of the given filepath"
  (let* ((len (length filepath))
	 (last_slash (get-rightmost-slash filepath)))
    (if last_slash (substring (+ 1 last_slash) (- len 1) filepath))))

(defun others-amos-peer()
  "Return all other amos peers except current running one, and the nameserver/s one"
  (let ((all_amos 
	 (mapcar (f/l (x) (oid-name (car x)))
		 (getfunction 'amos_servers nil))))
    (delete 'nameserver (delete _amosid_ all_amos))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Logging utilities
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "create function log_rawworkers(Charstring logdir)->Boolean 
         /*Broad cast to all rawworkers to log their activities.
           New born rawworker also does the same*/
        as foreign 'lograwworkers-+';")

(defun lograwworkers-+ (fno logdir res)
  (let ((p (fullpath logdir))
	(all_amos (others-amos-peer)))
    (cond ((directoryp p)
           (mapfunctionres 'dir (list p "*.log")nil 
			   (f/l (row)(delete-file (concat (add/last p)
							  (car row)))))
	   (mapc (f/l (peer)
		      (send-form `(redirect-to-logfile ,p) 
				 (port-of-peer peer)))
		 all_amos)
	   (setq *enable-rawworker-log* p)
	   (osql-result logdir p))
	  (t (error "Not a directory" p)))))  

(defun redirect-to-logfile (dir)
  "Redirect stdout to a filename"
  (let ((fname (add/last dir)))
    (cond (_amosid_ (setq fname (concat fname _amosid_ ".log")))
	  (t (setq fname (concat fname "client.log"))))
    (redirect-basic-stdout fname)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State update
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "create function updateState(Charstring command)->Object 
       /*Execute X on Master and broadcast command X to all peers.
         The result of applying X is returned*/
        as foreign 'updateState-to-peers-+';")

(defglobal _command-logs_ "")

(defun updateState-to-peers-+ (fn command res)
  "Excute command string X on Master and broadcast command X to all peers.
   The result of executing X is returned"
    (let ((all_amos (others-amos-peer)))
      ;; execute X and emit result
      (osql-result command (amos-execute command))
      ;; add command to the end of command logs
      (setq _command-logs_ (concat _command-logs_ " "  command))
      ;; broadcast command X to all other peers
      (mapc (f/l (peer)
		 (send-form (list 'within-lisp (parse command))
			    (port-of-peer peer))) all_amos)))

;; clear command-logs before saving image
(setq before-rollout-forms (cons `(setq _command-logs_ "") before-rollout-forms))
      

