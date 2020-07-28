 (defglobal _bt_ (make-btree))                                       

_mexima-enabled_                                       

(defun btree-build (size bt)
  (let ((sz (* size 2))
	(i 0))
    (while (< i size)
      (put-btree i bt i)
      (setq i (+ 1 i)))
    nil))                   

(btree-build 1000000 _bt_)                                      

;;(break put-2-darray)      

(rollout "foo.dmp")                                     
