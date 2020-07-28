(osql " create function string_explode(Charstring str, 
                Charstring delimiter)->Vector of Charstring 
as foreign 'string-explode-delimiter';")
(defun string-explode-delimiter (fn str delimiter res)
  (osql-result str delimiter (toarray (string-explode str delimiter))))


(defun gen-unique-string(prefix)
  (car (string-explode (concat prefix (* (rnow) 100000)) "."))) 

(osql " create function unique_string (Charstring prefix)->Charstring
         as foreign 'gen-unique-string-+';")

(defun gen-unique-string-+(fno prefix res)
  (osql-result prefix (gen-unique-string prefix)))
