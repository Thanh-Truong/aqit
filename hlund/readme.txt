The following notes describe the scenario.

- Log file keeps arriving at AmosNT/logDir/hlund/realdata/target

- Upon its arrival, a bulk loader tries to extract log data from a log file. 
  Then it bulks load log data into configured RDBMS over network.

-------------------------------------------
HOW TO 
-------------------------------------------
a) Configure RDBMS
see config.cmd which contains RDBMS configurations 
- database
- working table
- username
- passwork
...

b) Modify schema
see schema.sql 


c) Build and start instruction 

- Configure and compile : compile.cmd
- Run the system        : run.cmd -L scenario.lsp ( Temporarily disabled !!)

-------------------------------------------
Handling Hägglunds data
-------------------------------------------
- Log in into UDBLSERVER1
- Run compile.cmd
- Run scenario.cmd
-------------------------------------------
NOTES
-------------------------------------------
a) scenario.cmd will start 3 differents java processes but will not
close them properly.

Issue 'killall' to terminate all related processes

b) Scheduling bulkdeleter
A scheduled task 'bulkloader' might not invoke batch file bulkloader.bat.
If it is the case, set the current user the full control on the batch file
(Right click--Properties/Security tab )

The result of bulkloader will be flush to logdeleter.txt

To delete the task Schtasks /delete /TN bulkdeleter /F