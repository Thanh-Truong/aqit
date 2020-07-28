;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2007 Tore Risch, UDBL
;;; $RCSfile: multicast.lsp,v $
;;; $Revision: 1.6 $ $Date: 2012/02/23 20:27:38 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Function to multicast computations in parallel to peers
;;; =============================================================
;;; $Log: multicast.lsp,v $
;;; =============================================================



(defun pf0 (x s)
  (print x s)
  (flush s))

(defun multicast-receive-chunks0 (fno peers fn args res)
  (let* ((ports (mapcar (function port-of-peer) (arraytolist peers)))
         (sockets (mapcar (function port-socket) ports))
         (arglists (arraytolist args))
	 rd)
    (mapc (f/l (p argl);; start peers
	       (send-form (list 'start-function0 fn argl) p))
	  ports arglists)
    (while sockets;; Start receiving data from peers
      (let ((socks (poll-sockets (listtoarray sockets) 1)));; Poll parallell
	(cond ((null socks) nil);; Timeout
              (t (maparray socks 
			   (f/l (e i)
				(cond ((eq (setq rd (read e)) '*eof*)
				       ;; Stream done
				       (setq sockets 
					     (remove e sockets)))
				      (t
				       ;; emit
				       (osql-result peers fn args rd)))))))
	))))
   
(defun start-function0 (fn args)
  "This function runs on child and sends result back on client port"
  (let ((s (port-socket *client-port*))
        (fno (resolvename (mksymbol fn) args nil)))
    (mapfunction fno args
		 (f/l (row)
		      (pf0 (car row) s)))
    (pf0 '*eof* s)))
