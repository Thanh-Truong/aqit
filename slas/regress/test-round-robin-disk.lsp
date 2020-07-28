(checkequal 
 "Round robin disks"
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 1))) 0)) ;; disk 1  
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 2))) 0)) ;; disk 2
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 3))) 0)) ;; disk 3  
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 4))) 0)) ;; disk 4  
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 5))) 0)) ;; disk 5  
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 6))) 0)) ;; disk 6  
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 7))) 0)) ;; disk 7
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 8))) 0)) ;; disk 8
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 9))) 0)) ;; disk 9
 ((round-robin-disk)
  (elt (car (callfunction 'slasraw_disk  (list 10))) 0))) ;; disk 10 

(quit)  
