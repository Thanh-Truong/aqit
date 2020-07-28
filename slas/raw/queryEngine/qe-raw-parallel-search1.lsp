;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2007 Tore Risch, UDBL
;;; $RCSfile: qe_search.lsp,v $
;;; $Revision: 1.2 $ $Date: 2007/09/25 17:20:50 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Functions to multicast computations in parallel to peers
;;; =============================================================
;;; $Log: qe-raw-search-parallel.lsp,v $
;;; =============================================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Multicast receive from chunks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar *not-ready-peers*) ; counter of not ready peers
(defvar *multicastreceive-args*) ; arguments of multicastReceive

(defun multicast-receive-chunks1 (fno peers function arguments result)
  (let ((*not-ready-peers* (length peers)))
    (setq *multicastreceive-args* (list peers function arguments))
    (register-as-listening-peer);; Register as listening before multicasting
    (maparray peers;; Multicast function and arguments to the peers
	      (f/l (p i)
		   (send-form (list 'reply-to (kwote _amosid_)
				    (kwote function)
				    (aref arguments i))
			      (port-of-peer p))))
    (broadcast-eof peers)
    (run-until-all-received);; Wait for results to arrive
    ;; kill them all except the name server
    (maparray peers
	      (f/l (p i)
		   (send-form '(OR _nameserver_ 
				   (quit))
			      (port-of-peer p))))
    )) 


(defun broadcast-eof (peers)
  (maparray peers (f/l (p i)(send-form 
			     (list 'report-ready (kwote _amosid_))
			     (port-of-peer p)))))

(defun reply-to (peer fn args)
  "Send to PEER return stream from applying FN on ARGS"
  (let ((port (port-of-peer peer)))
    (mapfunctionres (getfunctionnamed (mksymbol fn))
		    args nil 
		    (f/l (row)(send-form 
			       (list 'peer-reply (kwote (car row)))
			       port)))
    ))

(defun report-ready (to)
  (send-form `(peer-ready (quote , _amosid_))(port-of-peer to)))

(defun peer-reply (val)
  "Emit received reply from peer"
  (apply 'osql-result (append *multicastreceive-args* (list val))))

(defun peer-ready (peer)
  "Register that another peer has sent all data"
  (1-- *not-ready-peers*))

(defun run-until-all-received ()
   "Receive answers until all peers ready"
   (while (> *not-ready-peers* 0) (check-descriptors 2)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun multicast-receive-chunks (fno vector_rwr function fanout result)
  (let* (lpeers peers *not-ready-peers* arguments (i 0))
    ;;(setq starttime (clock))
    (maparray vector_rwr ;; get list of peers name
	      (f/l (rwr i)
		   (let* ((port (caar (getfunction 'port (list rwr))))
			  (portname (port-name port)))
		     (setq lpeers (adjoin portname lpeers)))))  
    
    ;; make a vector of peers name
    (setq peers (toarray lpeers))
    (setq *not-ready-peers* (length peers))
    ;; build arguments, in this case it is a vector of empty vectors
    (while (< i fanout)
      (setq arguments (cons (vector) arguments))
      (1++ i))
    (setq arguments (toarray arguments))   
    
    ;; store this function signature to emit result later on
    (setq *multicastreceive-args* (list vector_rwr function fanout))
    (register-as-listening-peer);; Register as listening before multicasting
    (maparray peers;; Multicast function and arguments to the peers
	      (f/l (p i)
		   (send-form (list 'reply-to (kwote _amosid_)
				    (kwote function)
				    (aref arguments i))
			      (port-of-peer p))))
    (broadcast-eof peers)
    (run-until-all-received);; Wait for results to arrive
    ;; kill them all except the name server
    ;;(maparray peers
    ;;(f/l (p i)
    ;;(send-form '(OR _nameserver_ 
    ;;(quit))
    ;;(port-of-peer p))))
    ;; side-effect
    ;;(formatl t "multicast took " (- endTime startTime) " s" t)
    ))    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2014-03-07
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;create function mapSubQueryOnChunks(
;;        Vector of RawWorkerRemote vector_rwm, 
;;        Function job,        /*transient subquery function*/
;;        Vector args, 	      /*arguments of job*/
;;	  Number fanout)-> Object  /*number of dynamic generated nodes*/
;; as foreign 'mapSubQueryOnChunks1----+';
(defun mapSubQueryOnChunks1(fno vector_rwr job args fanout res)
  (let* (lpeers peers ports sockets arguments (i 0) rd)
    (maparray vector_rwr ;; get list of peers name
	      (f/l (rwr i)
		   (let* ((port (caar (getfunction 'port (list rwr))))
			  (portname (port-name port)))
		     (setq lpeers (adjoin portname lpeers)))))  
    ;; make a vector of peers name
    (setq peers (toarray lpeers))
    (setq ports (mapcar (function port-of-peer) (arraytolist peers)))
    (setq sockets (mapcar (function port-socket) ports))
    ;; define job. I make this part general enough
    (cond ((selectbody-p job)
	   (mapc (f/l (p) (define-job-on-rawworker0 job p)) ports))
	  ((transientp job)
	   (mapc (f/l (p) (define-job-on-rawworker3 
			    job p)) ports))
	  ((stringp job) 
	   (mapc (f/l (p) (define-job-on-rawworker2 job p)) ports))
	  (t (setq sockets nil))) ;; avoid infinity loop
    ;; run job
    (if sockets (mapc (f/l (p) (run-job-on-rawworker0 args p)) ports)) 
    
    (while sockets;; Start receiving data from peers
      (let ((socks (poll-sockets (listtoarray sockets) 1)))
	(cond ((null socks) nil);; Timeout
              (t (maparray 
		  socks 
		  (f/l (e i)
		       (cond ((eq (setq rd (read e)) '*eof*)
			      ;; Stream done
			      (setq sockets  (remove e sockets)))
			     (t ;; emit
			      (osql-result 
			       vector_rwr job args fanout rd))))))))))) 
