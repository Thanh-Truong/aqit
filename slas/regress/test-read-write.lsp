(with-directory 
  "../raw"
 (checkequal
  "Write a binary log file from a data stream with total 5 columns, in which column 4 is indexed"
  ((osql "slaslogger1(csv_file_tuples('data/measuredB.txt'), 4, 5, 'data/measuredB.bin');")
   'NIL))		
 (checkequal
  "Read a binary"
  ((osql "in(first_n(streamof(readblogfile('data/measuredB.bin', 5)), 10));")
   '((#(1.0 8.0 1313681285.3 1313681274.7 0.04))
     (#(1.0 8.0 1313681296.0 1313681296.0 0.0))
     (#(1.0 8.0 1313681296.1 1313681108.6 0.04))
     (#(1.0 8.0 1313681483.7 1313681483.7 0.0))
     (#(1.0 8.0 1313681483.8 1313680894.2 0.12))
     (#(1.0 8.0 1313682073.5 1313682073.5 0.0))
     (#(1.0 8.0 1313682073.6 1313681995.4 0.12))
     (#(1.0 8.0 1313682151.9 1313682151.9 0.04))
     (#(1.0 8.0 1313682152.0 1313682152.0 0.0))
     (#(1.0 8.0 1313682152.1 1313682149.2 0.04))))))

;; Create stream of windows from input stream 
(osql "create function windowsOfMeasurements()-> Stream of Window
       as wsCSVlogfile('data/measuredB.txt',3, 3);") 

(with-directory 
 "../raw"
 (checkequal
  "Test write windows of stream to binary log files"
  ((osql "count(write_window_blogfile(windowsOfMeasurements(),4,5, 'data/measuredB.bin'));")
   '((4509)))))



  
