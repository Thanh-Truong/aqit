;; Register two hoooks to restore Mexi indexes on relation
(register-rollout-form '(save-mexi-on-relation))
(register-connect-form '(load-mexi-on-relation))

(register-rollout-form '(save-mexi-foreign-on-relation))
(register-connect-form '(load-mexi-foreign-on-relation))

(defglobal _mexi-indexes-log_ nil)
(defglobal _mexiff-indexes-log_ nil)
;;------------------------------------------------------------------------
(defun put-index-to-front (owner idx)
  (let* ((tmp (remove idx (relation-indexes owner))))
    (push idx tmp) 			  
    (putobject owner 'indexes tmp))
  owner)

;; Relation having mexi objects
;; Mexi objects were restored by load-mexi already
;; Here we handle how to build indexes again
;; case 1) If there is a Hash index, other (mexi) indexes will be constructed
;;         based on the Hash index
;; case 2) No HASH, keep the extent of one of (mexi) indexes. The chosen index 
;;         will be placed at the very front of indexes. Therefore, when we build
;;         index again, it will base on the chosen one
(defun save-mexi-on-relation ()
  (setq _mexi-indexes-log_ nil)
  (maphash 
   (f/l (owner mexi)
	(let* ((indowner owner)  ;; relation
	       indexes kvpairs  mx
	       (hashidx (car (amosindexes-of-kind indowner 'HASH))))   
	  ;; other mexi indexes rather HASH
	  (setq indexes (remove hashidx (relation-indexes indowner nil)))
	  (dolist (idx indexes)
	    (setq mx (index-rows idx))
	    (setq kvpairs nil)
	    (cond ((and (is-mexi mx)  ;; case 2
			(eq hashidx nil) ;; no Hash, 
			(eq mexi mx)) ;; store extent of this mexi only but others
		   (setq kvpairs (build-extent-mexi mexi))
		   (put-index-to-front indowner idx)))
	    (if (is-mexi mx) ;; keep all mex indexes
		(push (list owner idx kvpairs) _mexi-indexes-log_)))
	  ;; case 1
	  (if hashidx
	      (put-index-to-front indowner hashidx))))
   _mexi-owners_)
  (clrhash _mexi-owners_))
;;------------------------------------------------------------------------
(defun load-mexi-on-relation () 
 (mapc (f/l(entry)
	    (let* ((indowner (first entry))  ;; relation
		   (ro (first entry))
		   (idx  (second entry))
		   (kvpairs(third entry))
		   (mexi (index-rows idx)))
	      (if (is-mexi mexi)
		  (if (arrayp kvpairs)
		      (restore-extent-mexi mexi kvpairs)
		    ;; otherwise, build index based on case1 HASH index or case 2 
		    ;; the stored extent mexi			
		    (buildindex ro idx)))))
       _mexi-indexes-log_)
 ;; clear the whole thing
 (setq _mexi-indexes-log_ nil))

;;------------------------------------------------------------------------
(defglobal _mexiff-owners_ (make-hash-table))
(defun save-mexi-foreign-on-relation ()
  (let* ((lmexi (list-mexiff-objects)) owner)
    ;; gather all relations needed to processed
    (clrhash _mexiff-owners_)
    (setq _mexiff-indexes-log_ nil)
    (dolist (mexiff lmexi)
      (setq owner (mexiff-owner mexiff))
      (cond ((and (neq owner nil) 
		  (eq (gethash owner _mexi-owners_) nil))
	     (puthash owner _mexiff-owners_ t))))   
    (maphash 
     (f/l (owner v)
	  (let* ((hashidx (car (amosindexes-of-kind owner 'HASH)))
		 (indexes (relation-indexes owner nil))
		 (mexiff nil))
	    (cond ((neq hashidx nil) ;; There is HASH index on relaiton
		   (put-index-to-front owner hashidx)))
	    
	    (dolist (idx indexes)
	      (setq mexiff (index-rows idx))
	      (cond ((neq (index-type idx) 'HASH)
		     (push (list owner mexiff idx 
				 (if (neq hashidx nil) nil (mexiff-buildextent idx mexiff)))
			   _mexiff-indexes-log_))))))    
     _mexiff-owners_));; end let
  ;; clear meta-data
  (clrhash _mexi-owners_)
  (clrhash _mexiff-owners_))

;;------------------------------------------------------------------------
(defun load-mexi-foreign-on-relation ()
  (mapc (f/l (item)
	    (let* ((owner (first item))
		   (mexiff (second item))
		   (idx (third item))
		   (extent (fourth item)))
	      (restore-mexiff mexiff nil)
	      (cond ((eq extent nil)		     
		     (buildindex owner idx)) ;; based on existing Hash index
		    (t (restore-extent-mexiff idx mexiff extent)))))
	_mexiff-indexes-log_)
  (setq _mexiff-indexes-log_ nil))