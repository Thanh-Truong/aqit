(defglobal _slasraw-current-disk_ 0)  

(defun slasraw-current-disk () 
  ;; Return current disk in round robin fashion
  (if (eq _slasraw-current-disk_ 0)
      (round-robin-disk)
    (elt (car (callfunction 'slasraw_disk  (list _slasraw-current-disk_))) 0)))

(defun slasraw-current-diskfn (fn res)
  (osql-result (slasraw-current-disk)))

(defun round-robin-disk ()
  ;; round robin disk to store data log or metadata
  ;; disk start from 1 
  (let ((totaldisks  (caar (getfunction 'slasraw_num_disks (list )))))
    (if (neq _slasraw-current-disk_ totaldisks)
	(1++ _slasraw-current-disk_)
      (setq _slasraw-current-disk_ 1))
    (elt (car (callfunction 'slasraw_disk  (list _slasraw-current-disk_))) 0)))     

(defun round-robin-diskfn (fn res)
  ;; round robin disk to store data log or metadata
  ;; disk start from 1 
  (osql-result (round-robin-disk)))

(osql "create function slasraw:round_robin_disk()->Charstring as foreign 'round-robin-diskfn';")
(osql "create function slasraw:current_disk()->Charstring as foreign 'slasraw-current-diskfn';")
