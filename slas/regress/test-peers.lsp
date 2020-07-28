(defglobal _portA_)
(defglobal _wstat_)
(defglobal _nwstat_)
(defglobal _startTime_)
(defglobal _oldCount_)
(defglobal _newCount_)   

(setq _startTime_ (round (/ (rnow) 100000)))
(setq _oldCount_ 11111)
(setq _newCount_ 99999)   

(osql "register('me');")

;; Test sender / receiver 
;;(start-program (executable) (concat " slasraw.dmp " "-ns")) ;; start nameserver        
(setq _portA_ (raw-spawn-receiver "s")) ;; start a peer and get hold on it       

;; make WinStats object
(setq _wstat_ (winstats-make _startTime_))
(setq _wstat_ (winstats-set-count _wstat_ _oldCount_))    

;; send it over another peer
(defmacro  parse-arguments (o) `,o)      

(socket-send `(setq a ,_wstat_) (port-socket _portA_))

;; maninpulate it there
(socket-send `(setq a (winstats-set-count a ,_newCount_)) (port-socket _portA_))

(socket-call (port-socket _portA_) 'winstats-start '(a)) 

;; get it back
(setq _nwstat_ (socket-eval 'a (port-socket _portA_)))
;; check it 
(checkequal 
 "Send and retrieve binary object between peers" 
 ((winstats-start _nwstat_)
  _startTime_))

(checkequal 
 "Manipulate binary object at other peer and retrieve back" 
 ((winstats-count _nwstat_)
  _newCount_))


;; quit
(socket-send '(quit) (port-socket _portA_)) ;; kill the peer   

;;(socket-send '(quit) (open-nameserver-socket)) ;; kill the peer
(sleep 0.5) ;; Make sure message sent
(unregister-amos _amosid_)
(quit) ;; Kill me    
;;(setq *nsp* (elt (car (callfunction 'unstringify (list (getenv 'NSPORT')))) 0))
