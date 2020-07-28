;; Common functions
(with-directory "common"
		(load  "format.lsp")
		(load  "string.lsp")
		(load  "misc.lsp"))

;; Functions to bulk load log files to RDBMS
(with-directory "bulkloader"
		(load "bulk.lsp"))

;; Functions to log a stream into CSV file for bulk loading laater
(with-directory "bulkload_logger"
		(load "logger.lsp"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SLASRAW starts from here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defparameter *enable-raw-query-parallel* nil) 
(defparameter *enable-raw-subquery-parallel* nil) 
(defparameter *enable-raw-query-sequential* nil) 
(defparameter *enable-rawworker-log* nil)

(with-directory "config"
		(load-amosql "slasraw-config.osql"))

(with-directory 
 "raw"
 (load "raw-roundrobin.lsp")
 (load "winstats/slwinstats.lsp")           ;; window statistic
 (load "raw-peers-commnunication.lsp")                     ;; peers (sender / receiver)
 (load-amosql "raw-schema.osql")            ;; SlasRaw schema (Log, Metadata, Chunk, etc..) 
 (load "raw-scan.lsp")                      ;; generated scan functions + scan
 (load-amosql "raw-scan.osql")              ;; Scan on raw file
 (load-amosql "raw-testmappedtype.osql")	   ;; Logged data stream is mapped to relation	
 (load-amosql "raw-stream.osql")            ;; Read and write streams
 (load-amosql "raw-generateMappedRelation.osql") ;; Generate the mapped relation for Logged
 (load-amosql "raw-logdatastream.osql")         ;; data stream 
 (load "raw-logdatastream.lsp"))

;; Foreign function in C to write / read / query on raw binary file
(with-directory "raw/slaslogger"
		(load-amosql "init.osql"))

(with-directory 
 "raw/queryEngine"
 (load-amosql "qe_coordinator.osql")
 (load "qe-coordinator.lsp")       ;; Raw Coordinaor
 (load "qe-raw-parallel-search0.lsp")   ;; Raw Search in parallel by spawning peers 
 (load "qe-raw-parallel-search1.lsp")   ;; Raw Search in parallel by spawning peers 
 (load "qe-raw-sequential-search.lsp")  ;; Raw Search in sequential without peers
 (load "qe-rawworker.lsp")
 (load-amosql "qe-rawworker.osql")
 (load "qe-raw-query-planer.lsp")  ;; Raw Query Engine )
 (load "qe-subplan1.lsp"))
;; configuration for Mac
(load-amosql "slasraw-config-mac.osql")

;; prompter is slas
(setq _prompter_ "SlasRaw")
(osql "debugging(true);")
 
;;(trace register-in-nameserver)
;;(trace unregister-amos)
;;(trace amos-shutdown-comm)
;;(trace initialize-communication)

;; Still does not work well 
;; (osql "logging off;")
;;(trace start-slasraw)
;;(trace raw-spawn-receiver)

;; all processes will log their activities
