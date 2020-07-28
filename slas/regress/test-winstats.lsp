
(checkequal 
 "make a window statistic no startTime"
 ((neq (winstats-make 0) nil) 'T)) 

;; A hack around to convert double to integer
(defglobal _startTime_)
(setq _startTime_ (round (/ (rnow) 100000))) 

(checkequal 
 "make a window statistic with startTime"
 ((winstats-start (winstats-make _startTime_))
  _startTime_))    

(checkequal 
 "count"
 ((progn 
    (defglobal _wstat_)
    (setq _wstat_ (winstats-make 0))
    (setq _wstat_ (winstats-set-count _wstat_ 1122))
    (winstats-count _wstat_))
  1122))    
  
 
	   
