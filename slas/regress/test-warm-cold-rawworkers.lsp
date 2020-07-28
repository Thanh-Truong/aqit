(cd "../raw/data")
(osql "register('me');")
(print "
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fullscan in parallel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
;;Enable search in parallel
(setq *enable-raw-query-parallel* t)
(osql "create function q1()-> Bag of (Number, Number, Number , Number) 
       as select m(lf) , s(lf) , bt(lf), et(lf) from LogFile_MeasuresB lf;")


(defun scan-parallel (time)
  (let ((startTime (clock))
	endTime)
    (checkequal
     "Test query planer - FULL SCAN in parallel"
     ((osql "count(q1());")
      '((99984))))
    (setq endTime (clock))
    (formatl t "The " time " time, it took " (- endTime startTime) " s" t)))

;; First time
(scan-parallel 1)
;; Second time should not spwan RawWorkers
(scan-parallel 2)
(scan-parallel 3)
(scan-parallel 4)

(cd "../../regress") 
