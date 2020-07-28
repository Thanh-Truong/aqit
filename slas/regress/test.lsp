slasraw.exe slasraw.dmp       

lisp;       

(break rewrite-rawcc-fn)          

(break raw-query-compile)    

(osql "set :s = streamof(csv_file_tuples('measuredB.txt'));
        set :lds = define_loggedstream(:s,  
                        'LogFile_MeasuresB',
                        {'m', 's', 'bt', 'et', 'mv'}, 
                        {4},                         
                        3);
")                 
(setq *enable-raw-query-engine* t)
(break rewrite-rawcc-test)           

(osql " create function q1()-> Bag of (Number, Number, Number , Number) 
        as select m(lf) , s(lf) , bt(lf), et(lf) from LogFile_MeasuresB lf where m(lf) > 1;")

(setq p (second pred))   

(pps (oid-propl (car p)))    

(setq fcc (car p))   

(getobject fcc 'loggeddatastream)  

create function q2()-> (RawLogFile, RawMetaFile)
as select chunks(lf) from LogDataStream lf;  

create function h1(Bag of Number b)->Boolean
as 
       for each Number d where d in b 
       begin
             print(d);
       end;  
