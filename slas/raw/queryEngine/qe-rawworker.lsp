;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RawWorker
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defstruct RawWorker state port datafile metafile cols)     
(defvar _rawworker_ nil "If it is a rawworker, this variable is filled") 
(defparameter *rawworker-timeout* 120.0) ;; timeout (seconds) for rawworker 

(defun  register-as-rawworker (dfp mfp cols) 
  ;; register this node as rawworker node
  ;; I want to quickly prototype SLASRAW
  ;; therefore, here I only send over data file path, meta file path only
  ;; (as Charstring) not the object
  ;; This is to avoid adding print/read binary for the object type
  (setq _rawworker_ (make-RawWorker :state _r-state-OK_ 
				     :port nil ;; the caller will update this field
				     ;; this to avoid problem of not serialized SOCKET
				     ;; datatype
				     :datafile dfp
				     :metafile mfp
				     :cols cols))
  ;; self-destruct after timeout elapsed
  (set-realtime-timer (progn (unregister-amos _amosid_) (quit)) *rawworker-timeout*))

(defun spawn-rawworker (rf mf &optional peername)
  "Spawn a RawWorker to query a given chunks.It returns port of the spawned RawWorker"
  (let (port dfp mfp cols)
    (setq dfp (caar (raw-filepath rf)))
    (setq mfp (caar (raw-filepath mf))) 
    (setq cols (caar (raw-cols mf))) 
    (setq port (raw-spawn-receiver "s" peername mfp))
    (cond ((port-p port)
	   (socket-send `(register-as-rawworker ,dfp ,mfp ,cols) (port-socket port))
	   port))))

(defun spawn-rawworkerfn (fn rf mf r)
  "Spawn a RawWorker to query a given chunks.It returns port of the spawned RawWorker"
  (osql-result rf mf (spawn-rawworker rf mf)))

(defun spawn-all-rawworkersfn (fn lds v)
  "Spawn all corresponding number of RawWorkers based on number of chunks.
   If some RawWorkers are still warm, they will be re-used.

   Re-use some warm RawWorkers is handled at raw-spawn-receiver in file raw-peers-communications.lsp
              Here I pass in a name of RawWorker. The name is composed of 'RAW_ON_CHUNK' and
              idno of rf (RawDataFile object)
   "
  (let ((bchunks (raw-lds-get-chunks lds))
	rf mf port lrwm)
    (mapcar (f/l (chunk) 
		 (setq rf (nth 0 chunk)) 
		 (setq mf (nth 1 chunk))
		 (setq port (spawn-rawworker 
			     rf mf (concat "RAW_ON_CHUNK" (getobject rf 'idno))))
		 (push (caar (getfunction 'make_rawworkerremote (list _r-state-OK_ port rf mf)))
		       lrwm))
	    bchunks)
    (osql-result lds (toarray lrwm))))
;;(trace spawn-rawworker)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FULLSCAN query on chunk
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun rawworker-fullscan-chunkfn (fn r)
  ;; RawWorker runs FULL SCAN on chunk 
  (let ((s (open-log-file-scan (rawworker-datafile _rawworker_) 
			       (rawworker-cols _rawworker_)))
	a)
    (while (not (scan-eos s))
      (setq a (car (scan-nextrow s)))
      (if (arrayp a)
	  (osql-result a)))))

(defun fullscan-datafile-chunkfn (fn datafile cols r)
  "fullscan given datafile and cols not by rawworker"
  (let ((s (open-log-file-scan datafile cols))
	a)
    (while (not (scan-eos s))
      (setq a (car (scan-nextrow s)))
      (if (arrayp a)
	  (osql-result datafile cols a)))))

