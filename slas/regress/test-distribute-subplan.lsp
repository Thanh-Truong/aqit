;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Send a transient function to a RawWorker node and 
;;  execute it
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "create function job(Number a)->Number b 
        as iota(1, a) + 4;") 
;; get selectbody of job
(setq sb (getselectbody (theresolvent 'number.job->number)))

;; spawn a RawWorker
(osql "register('mexhjj');")                    

(register-as-listening-peer)   

(setq p (raw-spawn-receiver "s"))                          

(setq fno  (predicate-function (selectbody-argl sb)
			       (selectbody-resl sb)
			       (selectbody-pred sb)))      

;; define a job remote
;;(send-form `(setq _rawworker-job_ (kwote ,fno)) p)  

;; OR define a job remote
;;(define-job-on-rawworker0 sb p)

;; run it
;; (run-job-on-rawworker0 (vector 5) p)                           

;;(defun retrieve-data (p)
;;  (let ((s (port-socket p))
;;	row)
;;    (poll-sockets (vector s) 0)   
;;    (while (neq (setq row (read s)) '*EOF*) (car row)))) 

(cd "../raw/data")
(osql "register('me');")   

(osql "create function job(Number a)->Number b 
        as iota(1, a) + 4;")      

(osql " set :sqfn = create_transient_function(#'job');")      

(osql " select lds into :lds from LogDataStream lds;")   

(break START-JOB-ON-RAWWORKER0) 

(osql " mapSubQueryOnChunks(spawn_all_RawWorkers(:lds),
            :sqfn, {5}, numChunks(:lds));")      
