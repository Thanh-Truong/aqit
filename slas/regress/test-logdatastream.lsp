
(with-directory 
 "../raw/data"
 ;;-----------------------------------------------------------------------------
 ;; DEFINE LOGGED STREAM
 (osql "set :s = streamof(csv_file_tuples('measuredB.txt'));
        set :lds = define_loggedstream(:s,  /*an input stream*/ 
                        'LogFile_MeasuresB',  /*mapped relation*/
                        {'m', 's', 'bt', 'et', 'mv'},  /*list of columns*/ 
                        {4},                          /*indexded positions*/
                        3);                           /*base window size*/
        ")                          
 ;;------------------------------------------------------------------------------
 ;; LOG IT 
 (checkequal 
  "Run logged stream"
  ((osql "run_loggedstream(:lds);")
   '((4509))))

 ;;-----------------------------------------------------------------------------
 ;; QUERIES
 ;; Query Type 1 Abnormal behaviour of past events based on threshold
 (checkequal 
  "Count # of sensor readings"
  ((osql "count(select m(lf) , s(lf) , bt(lf), et(lf) from LogFile_MeasuresB lf);")
   '((99984)))) 
 
 (checkequal 
  "Count # of sensor readings deviating from its expected value 11 
   (bars) more than 240 seconds"
  ((osql "count(select m(lf) , s(lf) , bt(lf), et(lf) 
                from LogFile_MeasuresB lf
                where abs(mv(lf) - 20) > 11 and et(lf) -bt(lf) >240.0);")
   '((50)))))
