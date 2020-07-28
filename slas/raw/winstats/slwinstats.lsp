;;; ============================================================
;;; AMOS2
;;; 
;;; Author: (c) 2013 Thanh Truong, UDBL
;;; $RCSfile: slwinstats.lsp,v $
;;; $Revision: 1.6 $ $Date: 2013/05/20 15:17:03 $
;;; $State: Exp $ $Locker:  $
;;;
;;; Description: The window statistic type WinStats
;;; =============================================================
;;; $Log: slwinstats.lsp,v $
;;;
;;; =============================================================
(defglobal _winstats_
  (createliteraltype 'winstats (list _collection_)  'SLWINSTATS))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Foreign function in LISP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun winstats-makefn+ (fno startTime wstats)
  (osql-result startTime (winstats-make startTime)))

(defun winstats-set-stats--- (fno wstats stat v res)
  (osql-result wstats stat v (winstats-set-stat wstats (string-upcase stat) v)))

(defun winstats-get-stats--- (fno wstats stat v)
 (let ((v  (winstats-get-stat wstats (string-upcase stat))))
   (osql-result wstats stat v)))
(defun winstats-start- (fno wstats start)
   (osql-result wstats (winstats-start wstats)))

(defun winstats-stop- (fno wstats stop)
   (osql-result wstats (winstats-stop wstats)))

(defun winstats-offset- (fno wstats offset)
   (osql-result wstats (winstats-offset wstats)))

(defun winstats-byte-size- (fno wstats bsize)
   (osql-result wstats (winstats-byte-size wstats)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Getters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; winstats-start
;; winstats-stop
;; winstats-offset
;; winstats-byte-size
;; winstats-count
(defun winstats-count (wstats)
  (winstats-get-stat wstats "COUNT"))
;; winstats-max
(defun winstats-max (wstats)
  (winstats-get-stat wstats "MAX"))
;; winstats-min
(defun winstats-min (wstats)
  (winstats-get-stat wstats "MIN"))
;; winstats-stdev
(defun winstats-stdev (wstats)
  (winstats-get-stat wstats "STDEV"))
;; winstats-avg
(defun winstats-avg (wstats)
  (winstats-get-stat wstats "AVG"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun winstats-set-start (wstats v)
  (winstats-set-stat wstats "START" v))

(defun winstats-set-count (wstats v)
  (winstats-set-stat wstats "COUNT" v))

(defun winstats-set-max (wstats v)
  (winstats-set-stat wstats "MAX" v))

(defun winstats-set-min (wstats v)
  (winstats-set-stat wstats "MIN" v))

(defun winstats-set-avg (wstats v)
  (winstats-set-stat wstats "AVG" v))

(defun winstats-set-stdev (wstats v)
  (winstats-set-stat wstats "STDEV" v))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AmosQL interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(osql "
create function make_winstats(Number startTime) -> Winstats
  as foreign 'winstats-makefn+';

create function setstats(Winstats ws, Charstring stat, Object v) -> Winstats
  as foreign 'winstats-set-stats---';

create function getstats(Winstats ws, Charstring stat, Object v) -> Winstats
  as foreign 'winstats-get-stats---';

create function start(Winstats ws)->Number as foreign 'winstats-start-';
create function stop(Winstats ws)->Number as foreign 'winstats-stop-';
create function offset(Winstats ws)->Number as foreign 'winstats-offset-';
create function bytesize(Winstats ws)->Number as foreign 'winstats-byte-size';

")
