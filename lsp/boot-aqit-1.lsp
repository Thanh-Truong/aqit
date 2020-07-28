(defparameter *aqit-gcp* nil)
(defparameter *print-aqit* nil)
(defglobal _aqit-supported-indexes_ (list 'MBTREE))
(defglobal _!=_ (getfunctionnamed 'OBJECT.OBJECT.!=->BOOLEAN))
(defglobal _<_ (getfunctionnamed  'OBJECT.OBJECT.<->BOOLEAN))
(defglobal _>_ (getfunctionnamed  'OBJECT.OBJECT.>->BOOLEAN))
(defglobal _>=_ (getfunctionnamed  'OBJECT.OBJECT.>=->BOOLEAN))
(defglobal _<=_ (getfunctionnamed  'OBJECT.OBJECT.<=->BOOLEAN))  
(defglobal _gt-comparisons_  (list _>_  _>=_) "The gt comparisons")
(defglobal _lt-comparisons_  (list _<_  _<=_) "The lt comparisons")

(load  "aqit_utilities.lsp")

;; User defined indexes on core cluster functions
(load  "ud-index-cc.lsp")

;; Load Late-TR rewrite
(load  "late-tr-rewrite.lsp")

;; Load AQIT strategry
(load  "miscv2.lsp")
(load  "algebraic-rules.lsp")
(load  "aqitv2.lsp")
;(load  "aqitnew.lsp")
;(load  "aqitmisc.lsp")

;; Load Distance based index rewrite
(load  "rewrite-matrix.lsp") 
(load  "dist-based-index-rewrite3.lsp")
;;(load  "rewrite-index-phases.lsp")
