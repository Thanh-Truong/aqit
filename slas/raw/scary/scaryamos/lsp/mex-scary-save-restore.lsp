;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2010 Thanh Truong, UDBL
;;; $RCSfile: mex-save-restore.lsp,v $
;;; $Revision: 1.15 $ $Date: 2013/08/06 16:19:54 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: Saving and restoring transient index data
;;; =============================================================
;;; $Log: mex-save-restore.lsp,v $
;;; Revision 1.15  2013/08/06 16:19:54  thatr500
;;; added check when mexi cannot be restored
;;;
;;; Revision 1.14  2013/08/01 12:58:23  thatr500
;;; refined code to save and restore mexima indexes as key value pairs
;;;
;;; Revision 1.13  2012/01/05 16:54:17  thatr500
;;; removed some old cold. To be added new code
;;;
;;; Revision 1.12  2012/01/04 17:43:05  thatr500
;;; save as array
;;;
;;; Revision 1.10  2012/01/04 16:47:56  thatr500
;;; *** empty log message ***
;;;
;;; Revision 1.9  2012/01/04 16:44:15  thatr500
;;; - maintain counter
;;; - use array instead of list. It gains 5MB (lesser) than the original MBTREE
;;;   for one million key/value pairs.
;;;
;;; Revision 1.8  2012/01/04 14:50:27  thatr500
;;; - allowed to extend indexing through Foreign function
;;; - add XTree as built-in index
;;;
;;; Revision 1.7  2012/01/02 08:45:59  thatr500
;;; compact list key, value pair
;;;
;;; Revision 1.6  2011/12/28 11:05:12  thatr500
;;; removed code
;;;
;;; Revision 1.5  2011/12/28 10:02:45  thatr500
;;; save / restore Mexi objects on Alisp (level)
;;;
;;; Revision 1.4  2011/12/27 09:44:57  thatr500
;;; organized codes
;;;
;;; Revision 1.3  2011/12/20 21:01:52  thatr500
;;; new way to load/restore transient indexes
;;;
;;; Revision 1.2  2011/12/13 10:01:11  thatr500
;;; use primary index (HASH) to save/restore transient indexes
;;;
;;; Revision 1.1  2011/12/02 12:46:54  thatr500
;;; MEXIMA saving / restoring
;;;
;;;
;;; =============================================================
;; Add hooks
(defglobal _mexi-objects_ (make-hash-table))
(defglobal _mexi-owners_ (make-hash-table))
(register-rollout-form '(save-mexi) 'first)
(register-init-form '(load-mexi))

(defglobal _kvpairs_ nil)
(defglobal _kvpos_ 0)

(defmacro for (var from to do)
  (subpair '(_var _from _to _do)  
	   (list var from to do)
	   '(let ((_var _from)) 
	      (while (< _var _to)
		_do
		(setq _var (1+ _var))))))  

(defun num-darray (num darray_size)
  (if (= (mod num darray_size) 0)
      (floor (/ num darray_size))
    (+ (floor (/ num darray_size)) 1))) 

(defun put-2-darray (e)
  (let* ((first_idx (floor (/ _kvpos_ 128)))
	 (second_idx (mod _kvpos_ 128))
	 (darray (aref _kvpairs_ first_idx))
	 (ndarray nil))
    (cond ((null darray) ;; initialize if needed
	   (seta _kvpairs_ first_idx (darray-make 128))
	   (setq darray (aref _kvpairs_ first_idx))))   
    (darray-set darray second_idx e)
    (cond ((= second_idx 127) ;; compress when possible
	   (seta _kvpairs_ first_idx (darray-compress darray))))))

(defun mex-accumulate-kv (k v) 
  ;; swipe all positions 0-2*cardinality -1  in one-look
  (put-2-darray k)
  (setq _kvpos_ (+ 1 _kvpos_))
  (put-2-darray v)
  (setq _kvpos_ (+ 1 _kvpos_)))

(defun build-extent-mexi (mexi) 
  (let* ((cardinality  (mexi-count mexi))
	(num_darray (num-darray (* 2 cardinality) 128))
	da)
    (setq _kvpos_  0)
    ;; make an array size num_darray of darrays
    (setq _kvpairs_ (make-array num_darray))
    (mexima-map mexi 'mex-accumulate-kv) ;; Get list k/v
    
    (setq _kvpairs_ (if (eq _kvpairs_ nil) 1 _kvpairs_))
    ;;(help 'me)
    _kvpairs_)) ;; return list of kv pairs
;;-----------------------------------------------------------------------------
(defun save-mexi ()
  (let* ((lmexi (list-mexi-objects))
	 owner ext) ;; num of key/value pairs
    (clrhash _mexi-objects_)
    (clrhash _mexi-owners_)
    (dolist (mexi lmexi)
      (setq owner (mexi-owner mexi))
      (cond ((eq owner nil)	
	     (setq ext (build-extent-mexi mexi))
	     (puthash mexi _mexi-objects_ ext))
	    (t 
	     ;; mexi on relation will be handled by 'mex-relation-save-restore.lsp'
	     ;; note that <owner, mexi> is the key
 	     (puthash owner _mexi-owners_ mexi)
	     ;; anyway, keep mexi sothat it will be restored first in load-mexi
	     (puthash mexi _mexi-objects_ t))))
    ;; avoid storing extra data
    (setq _kvpairs_ nil)))

;;-----------------------------------------------------------------------------
(defun restore-extent-mexi (mexi extent) 
  (let ((first_idx 0)
	(len (length extent))
	(darray nil)
	(second_idx 0) k v)
    (while (< first_idx len)
      (setq darray (aref extent first_idx))
      (if (darray-is-compressed darray)
	  (setq darray (darray-decompress darray)))
      (setq second_idx 0)
      (while (< second_idx 128)	
	(mexima-put (darray-get darray second_idx) mexi  
		    (darray-get darray (+ 1 second_idx)))
	(setq second_idx (+ 2 second_idx)))
      (setq first_idx (+ 1 first_idx)))))

(defun load-mexi ()
  (maphash (f/l 
	    (mexi kvpairs)
	    (if (restore-mexi mexi nil) ;; restore mexi object
		;; if there is its extent, it will be restored
		(cond ((arrayp kvpairs) 
		       (restore-extent-mexi mexi kvpairs)))))
	   _mexi-objects_)
  ;; empty after all
  (clrhash _mexi-objects_))
