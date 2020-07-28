all: setup setupdisks nameserver regress

regress:
	# Round robin disks
	slasraw.exe slasraw.dmp -L "test-round-robin-disk.lsp" -l "(quit)"
	# Test some misc functions
	slasraw.exe slasraw.dmp -L "test-misc.lsp" -l "(quit)"
	# Test split-join subquery plans
	slasraw.exe slasraw.dmp -L "test-split-join-subplans.lsp" -l "(quit)"
	# Test window statistic basic functions
	slasraw.exe slasraw.dmp -L "test-winstats.lsp" -l "(quit)" 
	# Test read and write text/binary log files (simple, one disk)
	slasraw.exe slasraw.dmp -L "test-read-write.lsp" -l "(quit)"
	# Test abnormality queries (scan approach)
	slasraw.exe slasraw.dmp -L "test-queries.lsp" -l "(quit)"
	# Test spawn peer and send binary WinStats back and forth
	slasraw.exe slasraw.dmp -L "test-peers.lsp" -l "(quit)"
	# Test some functions of LogDataStream
	slasraw.exe slasraw.dmp -L "test-logdatastream.lsp" -l "(quit)"
	# Test spawn and kill meta-data builder
	slasraw.exe slasraw.dmp -o "<'test-spawn-kill-metadataNode.osql';"
	# Setup disks
	@$(MAKE) --no-print-directory setupdisks
	slasraw.exe slasraw.dmp -L "test-round-robin-log-data.lsp" -l "(quit)"
	# Setup disks
	@$(MAKE) --no-print-directory setupdisks
	# Test generate chunks and do full scan
	@$(MAKE) --no-print-directory generatechunks
	@$(MAKE) --no-print-directory scanchunks
	@$(MAKE) --no-print-directory subqueryonchunks
	@$(MAKE) --no-print-directory killnameserver

# Clean up and compile
compile:
	cd .. && make clean && make

# Create data directories on different disks
setup:
	cd ../raw/data && if [ -a measuredB.bin ]; then rm measuredB.bin; fi;
setupdisks: 
	cd ../raw/data && rm -rf disk* && rm -f *_meta.dmp
	slasraw.exe slasraw.dmp -o "<'../config/setup_disks.osql';"

# Start a name server s
nameserver:
	slasraw.exe slasraw.dmp -n &

# kill the name server
killnameserver:
	slasraw.exe slasraw.dmp -L "test-kill-nameserver.lsp"
	sh $(AMOS_HOME)/bin/killall.sh >> /dev/null

# generate chunks
generatechunks:
	slasraw.exe slasraw.dmp  -L "test-generate-scan-chunks.lsp" -l "(rollout \"chunks.dmp\") (quit)"

# scan chunks
scanchunks:
	slasraw.exe chunks.dmp  -L "test-query-on-chunks.lsp" -l "(quit)"
# subquery/job on chunks
subqueryonchunks:
	slasraw.exe chunks.dmp  -O "test-subquery-on-chunks.osql"
warmcold:
	@$(MAKE) --no-print-directory setup
	@$(MAKE) --no-print-directory setupdisks
	@$(MAKE) --no-print-directory nameserver
	@$(MAKE) --no-print-directory generatechunks
	slasraw.exe chunks.dmp  -L "test-warm-cold-rawworkers.lsp" -l "(quit)"
	@$(MAKE) --no-print-directory killnameserver


# clean up
clean:
	cd .. && make clean
