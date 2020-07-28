(defglobal _socA_)   

;; Name server and a peer named p1
(start-program "amos2" " -ns")  

(start-program "amos2" "-s p1")
(wait-until-started '(p1))  

;; Set socket to p1
(setq _socA_ (open-socket-to 'p1)) 

;; do somethings with p1

;; save p1 database
(socket-send '(rollout "p1.dmp") _socA_)  

;; kill p1 and the nameserver
(socket-send '(quit) _socA_) ;; kill the peer   
(socket-send '(quit) (open-nameserver-socket))  

(sleep 0.5) ;; Make sure message sent
(quit) ;; Kill me     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   DO READ THE COMMENTS !!!!!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
;;; Start p1 within a name server
amos2 -q lisp 

(start-program "amos2" " -ns")) 

(start-program "amos2" " p1.dmp")) ;; or go to console and type amos2 p1.dmp to.  
;; It will failed also

(exit) 

;; Restore p1 database. It works but takes a while (not long time)
killall.cmd ;; or killall.sh

amos2 p1.dmp 

creae function test;;;; this should raises error but it will not

6d6d63abn;; this still okie

quit;


