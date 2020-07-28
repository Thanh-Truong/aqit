;;(load-extension "scaryamos" t)     

(defglobal _darray_ nil)
(setq _darray_ (darray-make 128))     
(defglobal _seed_ 10)
(defun initialize (darray size)
  (let ((i 0))
    (while (< i size)
      (darray-set darray i 
		  (cond ((numberp _seed_)
			 (+ _seed_ i))
			((stringp _seed_)
			 (concat "" _seed_ i))
			(t i)))
      (setq i (+ i 1)))))      

(defun test-put (darray size)
  (let ((i 0) v)
    (while (< i size)
      (setq v (darray-get darray i))
      (cond ((and (numberp v) 
		  (= (- v (+ _seed_ i)) 0)))
	    ((and (stringp v)
		  (equal v (concat "" _seed_ i))))
	    (t 
	     ;;(if (not 
	     (print (concat "Wrong! at " i " b/c it returned  " v))))
      (setq i (+ i 1)))))  

;; Test1
(initialize _darray_ 128) 
(test-put _darray_ 128) 

;; Test2
(setq _darray_ (darray-compress _darray_))
(setq _darray_ (darray-decompress _darray_))
(test-put _darray_ 128) 

;; Test3
(setq _darray_ (darray-compress _darray_))
(setq _darray_ (darray-decompress _darray_))
(test-put _darray_ 128) 

(setq _darray_ (darray-compress _darray_))
(rollout "scaryamos.dmp");
