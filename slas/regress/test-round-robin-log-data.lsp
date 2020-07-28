
(osql "imagesize 100000000;")                        

(osql "cd('../raw/data');")                        

(osql "set :s = streamof(csv_file_tuples('measuredB.txt'));")                        

(osql "set :lds = define_loggedstream(:s,                           
                              'LogFile_MeasuresB',           
                               {'m', 's', 'bt', 'et', 'mv'}, 
                               {4},                         
                                3);                                           
    ")                       

(osql "slasraw:log(:s, :lds);")                   

;;(osql "register('me'); kill_all_peers();raw_unregister_me();")
;; This is to wait the last chunk to be written into disk
(sleep 2)

(with-directory (caar (osql "slasraw_disk(1);"))
		(checkequal 
		 "Log data files and meta files in Disk1"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB0.dmp") ("LogFile_MeasuresB10.dmp")))))   
(with-directory  (caar (osql "slasraw_disk(2);"))
		(checkequal 
		 "Log data files and meta files in Disk2"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB1.dmp") ("LogFile_MeasuresB11.dmp")))))
(with-directory  (caar (osql "slasraw_disk(3);"))
		(checkequal 
		 "Log data files and meta files in Disk3"
		 ((osql "dir('.', '*.dmp'); ")
		  '(("LogFile_MeasuresB2.dmp")))))
(with-directory  (caar (osql "slasraw_disk(4);"))
		(checkequal 
		 "Log data files and meta files in Disk4"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB3.dmp")))))
(with-directory  (caar (osql "slasraw_disk(5);"))
		(checkequal 
		 "Log data files and meta files in Disk5"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB4.dmp")))))
(with-directory  (caar (osql "slasraw_disk(6);"))
		(checkequal 
		 "Log data files and meta files in Disk6"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB5.dmp"))))) 
(with-directory  (caar (osql "slasraw_disk(7);"))
		(checkequal 
		 "Log data files and meta files in Disk7"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB6.dmp")))))
(with-directory  (caar (osql "slasraw_disk(8);"))
		(checkequal 
		 "Log data files and meta files in Disk8"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB7.dmp")))))
(with-directory  (caar (osql "slasraw_disk(9);"))
		(checkequal 
		 "Log data files and meta files in Disk9"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB8.dmp")))))
(with-directory  (caar (osql "slasraw_disk(10);"))
		(checkequal 
		 "Log data files and meta files in Disk10"
		 ((osql "dir('.', '*.dmp');")
		  '(("LogFile_MeasuresB9.dmp"))))) 

