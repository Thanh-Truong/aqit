(defun raw-lds-get-columnNames (lds)
  ;; get list of column names of lds
  (let* ((colNames (getfunction 'columnNames (list lds)))
	 (arrayNames (if colNames (caar colNames))))
    (if (arrayp arrayNames)
	(arraytolist arrayNames))))

(defun raw-lds-get-cols (lds)
  ;; get number of cols
  (caar (getfunction 'cols (list lds))))  

(defun raw-lds-get-numChunks (lds)
  ;; get number of chunks
  (caar (getfunction 'numChunks (list lds))))    

(defun raw-lds-get-chunks (lds)
  ;; get of chunks = bag of (RawLogFile, RawMetaFile)
  (getfunction 'chunks (list lds)))

(defun raw-filepath (o)
  ;; get file path of o ( RawLogFile eller RawMetaFile)
  (getfunction 'filename (list o)))

(defun raw-cols (o)
  ;; get # cols of o ( RawLogFile eller RawMetaFile)
  (getfunction 'cols (list o)))

(defun raw-lds-get-chunks-++ (fn lds rf mf)
  ;; get of chunks = bag of (RawLogFile, RawMetaFile)
  (let ((b (getfunction 'chunks (list lds))))
    (mapcar (f/l (c) 
		 (osql-result lds (nth 0 c) (nth 1 c)))
	    b)))
(defun raw-lds-get-filename-chunks-++ (fn lds rfp mfp)
  ;; get of chunks = bag of (Charstring, Charstring)
  (let ((b (getfunction 'chunks (list lds))))
    (mapcar (f/l (c) 
		 (osql-result lds (caar (getfunction 'filename (list (nth 0 c))))
			      (caar (getfunction 'filename (list (nth 1 c))))))
	    b)))

(osql "create function getchunks(LogDataStream lds)->Bag of (RawLogFile, RawMetaFile)
       as foreign 'raw-lds-get-chunks-++';")

(osql "create function getchunks(LogDataStream lds)->Bag of (Charstring rfp, Charstring mfp)
       as foreign 'raw-lds-get-filename-chunks-++';")
