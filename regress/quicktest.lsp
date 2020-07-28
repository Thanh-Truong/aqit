(osql "
parteval('plus');
parteval('times');
                                             
create function p(Number x)->Boolean as stored;

create_index('p','x','mbtree','multiple');

for each Number i where i in iota(-20, 20)
   set p(i)=true;
")

(setq *enable-aqit* nil)

(defun less (x y)
  (< (car x) (car y)))


(osql "create function q1()->Number
        /* simple inequality */
         as select x from Number x
         where x+5<6 and p(x);")

(osql "create function q2()->Number
        /* simple inequality */
         as select x from Number x
         where 5/x<6 and p(x) and x !=0;")

(osql "create function q3()->Number
        /* simple inequality */
         as select x from Number x
         where 1-5/x<6 and p(x)  and x !=0;")

(osql "create function q4()->Number
        /* simple inequality */
         as select x from Number x
         where 1-5/x<6 and p(x)  and x !=0;")

(osql "create function q5()->Number
        /* simple inequality */
         as select x from Number x
         where (x-5)/x<6 and p(x)  and x !=0;")

(osql "create function q6()->Number
        /* simple inequality */
         as select x from Number x
         where abs(x-5)<6 and p(x)  and x !=0;")

(osql "create function q7()->Number
        /* simple inequality */
         as select x from Number x
         where abs((x-5)/x)<0.15 and p(x)  and x !=0;")

(defun test ()
  (checkequal  "Query results"
	       ((sort (osql "q1();") #'less)
		'((-20) (-19) (-18) (-17) (-16) (-15) (-14) (-13) (-12) (-11) (-10) (-9) (-8) (-7) (-6) (-5) (-4) (-3) (-2) (-1) (0)))
	       ((sort (osql "q2();") #'less)
		'((-20) (-19) (-18) (-17) (-16) (-15) (-14) (-13) (-12) (-11) (-10) (-9) (-8) (-7) (-6) (-5) (-4) (-3) (-2) (-1) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15) (16) (17) (18) (19) (20)))
	       ((sort (osql "q3();") #'less)
		'((-20) (-19) (-18) (-17) (-16) (-15) (-14) (-13) (-12) (-11) (-10) (-9) (-8) (-7) (-6) (-5) (-4) (-3) (-2) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15) (16) (17) (18) (19) (20)))	 
	       ((sort (osql "q4();") #'less)
		'((-20) (-19) (-18) (-17) (-16) (-15) (-14) (-13) (-12) (-11) (-10) (-9) (-8) (-7) (-6) (-5) (-4) (-3) (-2) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15) (16) (17) (18) (19) (20)))
	       ((sort (osql "q5();") #'less)
		'((-20) (-19) (-18) (-17) (-16) (-15) (-14) (-13) (-12) (-11) (-10) (-9) (-8) (-7) (-6) (-5) (-4) (-3) (-2) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15) (16) (17) (18) (19) (20)))
	       ((sort (osql "q6();") #'less)
		'((1) (2) (3) (4) (5) (6) (7) (8) (9) (10)))
	       ((sort (osql "q7();") #'less)
		'((5)))
		))




(defun rerun()
  (osql "
         recompile(#'q1');
         recompile(#'q2');
         recompile(#'q3');
         recompile(#'q4');
         recompile(#'q5');
         recompile(#'q6');
         recompile(#'q7');
"))

;; OFF
(setq *enable-aqit* nil)
(rerun)
(test)

;; ON
(setq *enable-aqit* t)
(rerun)
(test)


(test)