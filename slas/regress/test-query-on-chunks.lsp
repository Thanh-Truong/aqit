(cd "../raw/data")
(osql "register('me');")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test multicastReceiveChunks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "select lds into :lds from LogDataStream lds;")        
;;spawn_rawworker_on_chunk(chunks(:lds));      

(checkequal
 "Test multicastReceiveChunks - iota call"
 ((osql "select lds into :lds from LogDataStream lds;
         count(multicastReceiveChunks(spawn_rawworker_on_chunk(chunks(:lds)),
                      'iota', dummyRange(numChunks(:lds))));")     
  '((24)))) 

(checkequal
 "Test multicastReceiveChunks - this_amosid call"
 ((osql "select lds into :lds from LogDataStream lds;
         count(multicastReceiveChunks(spawn_rawworker_on_chunk(chunks(:lds)),
                      'this_amosid', dummyRangeEmpty(numChunks(:lds))));")
  '((12)))) 

(sleep 5.0) 

(checkequal 
 "No other peers are running"
 ((osql "other_peers();")
  'NIL))  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test multicastReceiveChunks No rewrite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(checkequal
 "Test multicastReceiveChunks - FULL SCAN"
 ((osql "select lds into :lds from LogDataStream lds;
         count(multicastReceiveChunks(spawn_rawworker_on_chunk(chunks(:lds)),
                      'rawworker_fullscan_chunk', dummyRangeEmpty(numChunks(:lds))));")
  '((99984))))   

(print "
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fullscan in parallel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
;;Enable search in parallel
(setq *enable-raw-query-parallel* t)
(osql "select lds into :lds from LogDataStream lds;
         
       create function q1()-> Bag of (Number, Number, Number , Number) 
       as select m(lf) , s(lf) , bt(lf), et(lf) from LogFile_MeasuresB lf;")

(setq startTime (clock))

(checkequal
 "Test query planer - FULL SCAN in parallel"
 ((osql "count(q1());")
  '((99984))))

(setq endTime (clock))
(formatl t "it took " (- endTime startTime) " s" t)

(print "
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fullscan in sequential on all chunks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
;;Enable search in sequential
(setq *enable-raw-query-parallel* nil)
(setq *enable-raw-query-sequential* t)

(osql "recompile('q1');");

(setq startTime (clock))

(checkequal
 "Test query planer - FULL SCAN in sequential"
 ((osql "count(q1());")
  '((99984))))

(setq endTime (clock))
(formatl t "it took " (- endTime startTime) " s" t)

(print "
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fullscan in 1 file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
(setq startTime (clock))
(checkequal 
 ""
 ((osql "count(select m , s, bt, et, mv
                from Number m, Number s, Number bt, Number et, Number mv 
                where (m,s, bt, et, mv) in  RawFile_Rawcc());")
  '((99984))))
(setq endTime (clock))
(formatl t "it took " (- endTime startTime) " s" t)

(cd "../../regress")
