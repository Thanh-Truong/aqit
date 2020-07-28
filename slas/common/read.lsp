(defun stream-ntuples-+ (fno filename delimiter r)
  "Emit stream of CSV rows"
  (with-input-file
   s filename
   (mapstream
    s #'read-line
    (f/l (row)
       (with-textstream
        tstr row
        (let (v)
         (mapstream
          tstr #'(lambda (str) (read-token str delimiter))
          (f/l (o)
               (setq v (push-vector v o))))
         (osql-result filename v)))))))  

