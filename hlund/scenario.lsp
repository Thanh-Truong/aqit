(defvar *b*)
(defvar *c*)
(defvar *fw*)
;; Name server
(start-program "run" "-n")
;; Create bulk loader node
(start-program "run" "-s b")
;; Create file watcher
(start-program "run" "-s fw")
(wait-until-started '(b fw))

;; Continously bulk load log event stream into parameterized RDBMS
(setq *b* (open-socket-to 'b))
(send-statement "< 'bulkloader.osql';" *b*)

(setq *fw* (open-socket-to 'fw))
(send-statement "< 'file_reporter.osql';" *fw*)

;; Create file copier node
(start-program "run" "-s c")
(wait-until-started 'c)
;; Simulate log files arriving
(setq *c* (open-socket-to 'c)) 
(send-statement "sleep(1.0); 
  copier(pwd()+'/../../logdir/hlund/realdata/',pwd()+'/../../logdir/hlund/realdata/target/',3);
   sleep(1.0); quit;" *c*)
;; Delay
(sleep 100)
;; Close all (c was closed already)
(send-statement "quit;" *b*) ;; Will not close B
(send-statement "quit;" *fw*) ;; Will not close B
(send-statement "quit;" (open-nameserver-socket))
;; Since I do not know how to send INTERRUPT ( Ctrl-C) to node B. It is a fiercely solution
(system "killall")
(quit)

