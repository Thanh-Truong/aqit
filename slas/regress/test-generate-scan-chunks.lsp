;;(osql "imagesize 100000000;")                       
(cd "../raw/data")            
(osql "register('me');")                  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test log data stream into chunks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "updateState(\"set :s = streamof(csv_file_tuples('measuredB.txt'));\");")     

(osql "updateState(\"set :lds = define_loggedstream(:s, 'LogFile_MeasuresB',
                                            {'m', 's', 'bt', 'et', 'mv'}, 
                                            {4}, 3);\");")     

;;if (this_amosid()="NIL") then register("Slasraw:Log"); 


(osql "slasraw:log(:s, :lds);")           



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test properties of LogDataStream
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Get the lds instance
(setq lds (caar (osql "select lds from LogDataStream lds;")))               

(checkequal 
 "Get colum Names"
 ((raw-lds-get-columnNames lds)
  '("m" "s" "bt" "et" "mv")))              

(checkequal
 "Get # cols"
 ((raw-lds-get-cols lds)
  '5))              

(checkequal
 "Get # chunks"
 ((raw-lds-get-numChunks lds)
  '12))             

(checkequal
 "Get chunks"
 ((length (raw-lds-get-chunks lds))
  '12))           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test spawn a RawWorker
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;(osql "register('me');")                   

(setq chunk (car (raw-lds-get-chunks lds)))         
(setq rf (car chunk))
(setq mf (cadr chunk))           

(setq port (raw-spawn-receiver "s"))            

(setq dfp (caar (raw-filepath rf)))
(setq mfp (caar (raw-filepath mf)))         

(socket-send `(register-as-rawworker ,dfp ,mfp) (port-socket port))         

(osql "kill_all_peers();")    

;; this kills all other peers except the current one
;; and the name server. The current one will be killed automatically 
;; when it is shutdown.
;; check AmosNT/lsp/comm.lsp and search for "amos-shutdown"

(osql "raw_unregister_me();")  

(cd "../../regress")   
