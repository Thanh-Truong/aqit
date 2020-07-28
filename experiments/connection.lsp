
(defun getEngine () 
  (string-upcase (getenv "engine")))

(defun getDatabase () 
  (string-upcase (getenv "database")))

(defun getAddress () 
  (string-upcase (getenv "address")))

(defun getPortDB () 
  (string-upcase (getenv "portdb")))

(defun getUsername (fn res) 
  (osql-result (getenv "username")))

(defun getPassword (fn res) 
  (osql-result (getenv "password")))

;; support MySQL or SQLSERVER
(defun sqlserver? ()
  (let* ((engine (getEngine)))
      (string= engine "SQLSERVER")))


(defun jdbc-string (fn res)
  (let* ((sqlserver (sqlserver?))
	 (driver (if sqlserver  "com.microsoft.jdbc.sqlserver.SQLServerDriver"
			     "com.mysql.jdbc.Driver")))
    (osql-result (concat "jdbc('aqit','" driver "');"))))


(defun dburl-string (fn res)	
  (let* ((sqlserver (sqlserver?))
	 (url (if sqlserver  "jdbc:microsoft:sqlserver://" "jdbc:mysql://")))     
      
    (osql-result 
     (if sqlserver (concat url (getAddress) ";DatabaseName=" (getDatabase))
       (concat url (getAddress) ":" (getPortDB) "/" (getDatabase))))))


(defun getDatabasefn (fn res) 
  (osql-result (getDatabase)))

(osql "create function jdbc_string()->Charstring as foreign 'jdbc-string';")
(osql "create function dburl_string()->Charstring as foreign 'dburl-string';")     
(osql "create function getusername()->Charstring as foreign 'getUsername';")     
(osql "create function getpassword()->Charstring as foreign 'getPassword';")     
(osql "create function getdatabase()->Charstring as foreign 'getDatabasefn';")     


(defun open-writefile-opt (fno filename opt)
  (setq *mystream* (openstream filename opt)))

(osql "create function openwritefile(charstring filename, charstring opt)
       ->boolean as foreign 'open-writefile-opt';")

(defun get-machines (fn res)
  (osql-result (listtoarray (mapcar (f/l (i) (mkatom i)) 
				    (string-explode (getenv 'machines) ",")))))

(osql "create function get_machines()-> Vector of Number as foreign 'get-machines';")
