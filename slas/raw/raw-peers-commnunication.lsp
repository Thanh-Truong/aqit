(defglobal _r-state-OK_ 1)
(defglobal _r-state-OVERFLOW_ -1) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NODE SCHEMA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "create type SlasRawNode properties (state Number, Port port);") 
(defglobal _socket_
  (createliteraltype 'socket (list _collection_)  'SOCKET))

 (defun portname-+ (fn p r)
   ;; get portname of port
   (osql-result p (mkstring (port-name p)))) 


(defun start-slasraw (prog &optional params background)
  "Start background program with given command line parameters"
  (let ((env (system-environment))
	(bkground (if background "&" "")))
    (cond ((equal env "VisualC++")
	   (system (concat "start /min " prog " " (or params ""))))
	  ((member env '("Unix" "Apple"))
	   (system (concat prog " " (or params "") bkground)))
	  (t (raise-error _cant-start_ env)))))

(defun executable()
  (caar (getfunction 'prepstartcmd (list "")))) ;; process command

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SENDER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spawn a new metadata receiver
(defun raw-spawn-receiver (server &optional pname dbname)
  "Spawn a raw peer with a given name if the name was not registered yet.
   Otherwise, return the peer associated with that name"
  (let* ((exe  (executable))
	 spname p)
    (if (null pname)                                  ;; if there is no peer name provided
	(setq pname (gen-unique-string "RAW")))       ;; generate unique peer name
    (setq spname (mksymbol pname))
    (if (null (is-running (string-upcase pname)))     ;; this peer is not started yet
	(progn
	  (start-slasraw exe (concat " " (if (null dbname) " slasraw.dmp "
					   dbname)
				     " "  " -s "   spname  " ") t)
	  (wait-until-started (list pname) t)
	  (setq p (port-of-peer spname))
	  ;; enable remote log ?
	  (if *enable-rawworker-log*
	      (if dbname
		  (socket-send `(redirect-to-logfile (getdir-from-filepath ,dbname))
			       (port-socket p))
		(socket-send `(redirect-to-logfile *enable-rawworker-log*)
			     (port-socket p))))
	  ;; update states
	  (if _command-logs_
	      (send-form (list 'within-lisp (parse _command-logs_)) p))

	  ))
    (port-of-peer spname))) ;; when the peer was started before
;; and currently is sitting in the pool, just return its port

;; Send window statistic
(defun raw-send-winstats (port wstat)
  (socket-eval `(add-winstats ,wstat) (port-socket port)))
  ;;(socket-send `(add-winstats ,wstat) (port-socket port)))

(defun raw-spawn-receiverfn (fn server pname port)
  (osql-result server pname (raw-spawn-receiver server pname)))      

(defun raw-send-winstatsfn (fn port wstats state)
  (osql-result port wstats (raw-send-winstats port wstats))) 

(defun raw-save-receiverfn (fn port name res) 
  (osql-result port name (socket-send `(progn 
					 (rollout ,name) 
					 (setq _windows_stats_ (make-btree "MBTREE"))
					 (setq _winstats_count_ 0))
				      (port-socket port))))

(defun raw-quit-receiverfn (fn port res)
  ;(socket-send '(quit) (port-socket port))
  (send-form '(or _nameserver_ (quit)) port)
  (sleep 0.5) ;; make sure the message sent
  (close-socket (port-socket port))
  (osql-result port t))

(defun raw-saveandquit-receiverfn (fn port name res) 
  (socket-send `(progn
		  (unregister-amos _amosid_)
		  (rollout ,name)
		  (quit))
	       (port-socket port))
  (sleep 0.5) ;; make sure the message sent
  (close-socket (port-socket port))
  (osql-result port name t))
	     
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RECEIVER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
(defglobal _windows_stats_ (make-btree "MBTREE"))
(defglobal _winstats_count_ 0);; This is a hack to fake the overflow scenario
(defglobal _limit-imagesize_ 9858730.0)  ;; in bytes 

(defun add-winstats (wstat)
  (put-btree (winstats-start wstat) _windows_stats_ wstat)
  (1++ _winstats_count_)
  (if (< _winstats_count_ 400)
  ;;(if (< (imagesize) _limit-imagesize_)
      _r-state-OK_
    _r-state-OVERFLOW_))

(defun raw-unregister-mefn (fn r)
  (osql-result (amos-shutdown-comm)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AMOSQL Interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "create function raw_spawn_receiver(Charstring servername, Charstring pname)->Port
      /* Spawn a new receiver and return a Port connected to it*/
       as foreign 'raw-spawn-receiverfn';")     

(osql "create function raw_send_winstats(Port port, Winstats wstats)->Number
      /* Push window statistic (wstats) to the receiver associated with soc
         2014-03-20 There is no ack !!
         The callee will notify the caller when it is reaching to the limit
      in a seperate reply */
       as foreign 'raw-send-winstatsfn';")     

(osql "create function raw_save_receiver(Port port, Charstring name)->Boolean
      /* Roll out as name.dmp and shut down the receiver*/
       as foreign 'raw-save-receiverfn';")     

(osql "create function raw_quit_receiver(Port port)->Boolean
       as foreign 'raw-quit-receiverfn';")     

(osql "create function raw_saveandquit_receiver(Port port, Charstring name)->Boolean
       as foreign 'raw-saveandquit-receiverfn';")     

(osql "create function raw_unregister_me()->Boolean as foreign 'raw-unregister-mefn';") 


(osql "create function raw_spawn_node(Charstring pname)->SlasRawNode node
      as begin
          create SlasRawNode(state, port) instances node (1, raw_spawn_receiver('s', pname));
          return node;
      end;") 
(osql "create function raw_send_to_node(SlasRawNode node, WinStats wstats)->Number
       as return raw_send_winstats(port(node), wstats);")

(osql "create function portname(Port p)->Charstring
       as foreign 'portname-+';") 


(quote
 (progn 
   (defglobal i 0)
   (defglobal tmp nil)
   (setq i 0)
   (setq tmp nil)
   (while (< i 10000)
     (setq tmp (winstats-make i))
     (put-btree (winstats-start tmp) _windows_stats_ tmp)
     (1++ i))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Some patches / fixes solely for my purpose
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun run-server ()
  "Redefine run-server function to print appropriate message"
  (register-as-listening-peer)
  (cond (_nameserver_ 
	 (princ "Name server " t))
	(_rawworker_
	 (princ "RawWorker " t))
	((string-like-i _amosid_ "*MetadataBuilder*")
	 (princ "MetadataBuilder " t))
	(t (princ "RawWorker " t)))
  (formatl t _amosid_ " is spawned " _listenport_ t)
  (if (null (assoc 'server _comm-state_))
      (setq _comm-state_ (nconc1 _comm-state_ (list 'server T))))
  (server-loop)) 


;;(trace raw-spawn-receiver)

(defun initialize-communication ()
  "Initialize communication after rollin"
  (setq _amosid_ nil)
  (setq _nameserver_ nil)
  (clrhash _portnametbl_)
  ;; newly added
  (setq _nameserverhost_ nil)
  (setq _comm-state_ nil)
  (setq _listening_ nil)
  ;; end
  (setq _listenport_ nil))

(quote
 (progn
   (setq _amosid_ nil)
   (setq _nameserver_ nil)
   (clrhash _portnametbl_)
   (setq _listenport_ nil)
   (setq _comm-state_ nil)
   (setq _listenport_ nil)
   (setq _nameamos_ nil) 
   (setq *client-port* nil)
   (setq *connectionless* nil)
   (setq *serverlog* nil)
   (setq _client-system_ nil)
   (setq _amos-named_ nil)
   (setq _local-amos-servers_ nil)
   (setq _listening_ nil)
   (setq _pending-coroutines_ nil)))
