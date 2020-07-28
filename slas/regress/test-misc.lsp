(checkequal
 "From Vector of columns to comma seperate columns"
 ((osql "raw_generateColumns({'m', 's', 'bt', 'et', 'mv'}, 5, ',');")
  '(("Number m,Number s,Number bt,Number et,Number mv"))))     

(checkequal
 "Generate core cluster"
 ((osql " create LogDataStream (mappedRelation) instances :lds ('MeasuredB');
   raw_generateCoreCluster({'m', 's', 'bt', 'et', 'mv'}, 'MeasuredB', :lds);")
  '(("create function MeasuredB_rawcc()->Bag of (Number m,Number s,Number bt,Number et,Number mv) as foreign 'raw-fullscan-nochunks-MeasuredB';"))))    

(checkequal
 "Generate mapped relation"
 ((osql "raw_generateMappedRelation({'m', 's', 'bt', 'et', 'mv'}, 'MeasuredB');")
  '((TRUE))))

(checkequal
 "Generate SQL Proxy"
 ((osql "raw_generateSQLProxy({'m', 's', 'bt', 'et', 'mv'}, 'MeasuredB');")
  '(("create function sql:MeasuredB()->(Number m,Number s,Number bt,Number et,Number mv) as in (MeasuredB_rawcc());"))))   

