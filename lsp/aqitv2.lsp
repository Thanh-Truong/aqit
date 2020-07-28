;; Node structure
(defstruct node pred arc)
;; Aqit record (iip, rest, visited)
(defstruct arec iip rest visited)
;;--------------------------------------------------------------
(defun aqit-fixpoint (pred)
 "Until no change do transform_pred" 
  (let ((oldpred pred) (newpred pred))
    (setq newpred (transform-pred oldpred))
    (while (not (equal-lists newpred oldpred)) ;; until no change 
      (setq oldpred newpred)
      (setq newpred (transform-pred oldpred)))
    (if (equal-lists pred newpred) ;; not success
	pred (aqit-gcp newpred))))
;;--------------------------------------------------------------
(defun transform-pred (pred)
  "Input: A predicate.
   Output: A transformed predicate if possible, otherwise orginal pred"
  (if (and (predicate-p pred)
	   (not (assq 'optional pred)))
      (let (res)
	(setq res
	      (selectq (car pred)
		       (or (let ((branches (cdr pred))
				 failure b nb resl)
			     ;; untill all branches are successfully transformed
			     (while (and (not failure) (neq branches nil))
			       (setq b (pop branches))
			       (setq nb (transform-pred b))
			       (if nb (setq resl (cons nb resl))
				 (setq failure t)))
			     ;; not all branches were transformed ? return null
			     (if (null failure) (orify resl))))
		       (and (let* ((path (chain pred))
				   (exposedpath (if path (expose path))))
			      (if exposedpath 
				  (subsitute pred path exposedpath))))		   
		       nil))
	(if res res pred))
    pred))
  ;;--------------------------------------------------------------
(defun chain (pred &optional irec)
  "Input: A conjunction of predicates pred.
   Output: A IIP if found, otherwise null"
  (let* ((npred (cdr (unandify pred)))
	 (orblocks (subset npred (f/l (p) (disjunctionp p))));; or blocks	 
	 ;; and block (only one because of unandify was applied)
	 (andblock1 (subset npred (f/l (p) (not (disjunctionp p)))))
	 (dt (simplify-division-tester andblock1)) ;; division test
	 (andblock (if dt (simplify-division-writer dt andblock1) andblock1)) ;; simplify division
	 nirec iv p rest)
    (cond ((null irec)
	   (setq iv (first-not-exposed-indexed-variable andblock))
	   (setq p (first-indexed-pred andblock iv))
	   (setq rest (remove p andblock))
	   ;;(if (and iv p) ;; cannot found an origin node
	   (setq irec (make-arec :iip (list (make-node :pred p :arc iv)) :rest rest :visited (list iv))))
	  (t  
	   (setf (arec-rest irec) (append2 (arec-rest irec) andblock))))	 
    ;; if there is a partial IIP, extend it with rest
    (setq nirec (extend-partial-iip (copy-arec irec)))
    (cond (nirec ;; found IIP, then join orblocks --> nirec.rest and return it
	   (setf (arec-rest nirec) (append2 (arec-rest nirec) orblocks))
	   nirec)
	  ((and (null nirec) (null orblocks)) nil)    ;; not found IIP and no orblocks
	  ;; not found IIP and there are some orblocks
	  ((and (null nirec) (neq orblocks nil))
	   (let* ((norblocks orblocks) otherorblocks
		  ob nob 
		  success nnirec)
	     ;; until one orblock ob succeeded or no more disjunction to try
	     (while (and  norblocks 
			  (null success))
	       (setq ob (pop norblocks))
	       (setq nnirec (chain-orpred ob (copy-arec irec)))
	       (setq success nnirec))
	     (if success
		 (progn		   
		   (setq otherorblocks (remove ob orblocks))
		   ;; distribute irec into other orblocks
		   (setq otherorblocks (mapcar (f/l (b) (distribute irec b)) 
					       otherorblocks))
		   (andify (adjoin nnirec otherorblocks)))))))));;return 
;;--------------------------------------------------------------
(defun chain-orpred (orpred &optional irec)
  "Input : A disjunction predicate and irec.
   Output: A disjunction IIP, otherwise null"
  (let ((success t) b (branches (cdr orpred)) nirec lb)
    (while (and success ;; IIPs have to be found on all branches
		(neq branches nil))
      (setq b (pop branches))
      (setq nirec (chain b (copy-arec irec)))
      (if (null nirec)
	  (setq success nil)
	(setq lb (cons (copy-arec nirec) lb))))
    (if success
	(orify lb))))
;;--------------------------------------------------------------
(defun extend-partial-iip (irec)
  "Input: A arec record containing iip, rest, visited.
   Output: A completed arec, otherwise null"
  (let* ((node (first (arec-iip irec)))
	(p (node-pred node))
	(v (node-arc node))
	(rest (arec-rest irec))
	cv q (n1irec (copy-arec irec)) n2irec candvars anode)
    ;n1
    (while (and rest
		(not (complete-iip (arec-iip n1irec)))) ;; iip is still not complete yet
      (setq q (pop rest))
      (cond ((connected q v (arec-rest n1irec))
	     (setf (arec-rest n1irec) (remove q (arec-rest n1irec)))
	     (setq candvars (subset (predicate-arguments q)
				    (f/l (arg) (and (not (osql-constantp arg))
						    (not (in arg (arec-visited n1irec)))))))
	     ;; n2	
	     (setq n2irec (copy-arec n1irec))
	     (setf (arec-iip n2irec) (cons (make-node :pred  q :arc nil) (arec-iip n2irec)))
	     (while (and (neq candvars nil) ;; still some variables to try
			 (not (complete-iip (arec-iip n2irec)))) ;; iip is still not complete yet
	       (setq cv (pop candvars))
	       (setf (arec-visited n2irec) (cons cv (arec-visited n2irec)))
	       (setq anode (car (arec-iip n2irec)))
	       (setf (node-arc anode) cv)
	       (if (not (complete-iip (arec-iip n2irec))) ;; not complete continue to extend
		   (setq n2irec (extend-partial-iip (copy-arec n2irec))))
	       ;;(help 'me)
	       (cond ((null n2irec) ;; start over with a new candidate variable
		      (setq n2irec (copy-arec n1irec))
		      (setf (arec-iip n2irec) (cons (make-node :pred  q :arc nil) (arec-iip n2irec))))));e While
	     (if (complete-iip (arec-iip n2irec))
		 (setq n1irec (copy-arec n2irec))))));; this will break the outer while loop
    (if (complete-iip (arec-iip n1irec)) n1irec)))
;;--------------------------------------------------------------
(defun expose (irec)
  (cond ((disjunctionp irec)
	 (let ((branches (cdr irec))
	       failure birec nbirec resl)
	   (while (and (not failure) (neq branches nil)) ;; untill all branches are successfully exposed
	     (setq birec (pop branches))
	     (setq nbirec (expose birec))
	     (if nbirec (setq resl (adjoin nbirec resl))
	       (setq failure t)))
	   ;; not all branches were exposed ? return null
	   (if (null failure) (orify resl))))
	((no-intermediate-nodes (arec-iip irec)) ;; no more intermediate-nodes  
	 (andify (append2 (iip-to-list (arec-iip irec)) (arec-rest irec))))
	(t (let* (resl rule (lrules _aqit-algebraic-rules_) rulefound )
	     (while (and (setq rule (pop lrules)) (null rulefound))
	       (cond ((test-LHS rule irec)
		      (setq resl (apply-RHS rule irec))
		      (setq rulefound t))))
	     (cond ((disjunctionp resl)
		    (orify (mapcar 
			    (f/l (b) (expose (new-arec irec b))) (cdr resl))))
		   ((null resl) nil)
		   (t ;; Continute exposing
		    (expose (new-arec irec resl))))))))
(defun subsitute (pred oldirec exposedirec) exposedirec)

	    
		 
			      
		  
			       
