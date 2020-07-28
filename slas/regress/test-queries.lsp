

;; SQL queries: Abnormal behaviour of past events based on threshold
(with-directory 
 "../raw/data"
 (checkequal 
  "Count # of sensor readings"
  ((osql "count(sql('select m , s, bt, et, mv from RawFile'));")
   '((99984)))) ;; 2013-Nov-11 Quick fix to pass the regression test
 
 (checkequal 
  "Count # of sensor readings deviating from its expected value 11 (bars) more than 240 seconds"
  ((osql "count(sql('select m , s, bt, et, mv from RawFile where
                 abs(mv - 20) > 11 and et-bt>240.0'));")
   '((50))))

 (checkequal 
  "Number of tumbling timestamp windows (stride: 3s, slide: 3s)"
  ((osql "count(in(wsblogfile('measuredB.bin', 5, 3, 3)));")
   '((4508)))) ;; 2013-Nov-11 Quick fix to pass the regression test
)

(osql "
   create RawLogFile(filename) instances :rf ('../raw/data/measuredB.bin');
   set :s = raw_open(:rf, 5);
   /*print(next(:s));
   print(raw_next(:rf));*/")

(checkequal
 "Scan - gets first element"
 ((osql "raw_next(:rf);")
  '((#(#(1.0 8.0 1313681285.3 1313681274.7 0.04))))))

