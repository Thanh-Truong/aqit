all:
	cd ../system/Unix/ && make
	cd ../validate && chmod +x install.sh
	cd ../validate/ && make && ./install.sh
	cd raw/slaslogger && make
	chmod +x $(AMOS_HOME)/bin/slasraw.exe
	slasraw.exe  svali.dmp -L "boot.lsp" -l "(rollout "\"../bin/slasraw.dmp"\") (quit)"
clean:
	cd regress && rm -f *.dmp
#	cd ../bin/ && rm -rf slasraw.dmp
	cd ../bin/ && rm -rf *.dmp
	cd raw/lofixS && make clean
	cd raw/lofixP && make clean
	cd raw/slaslogger && make clean
	cd raw/data && rm -rf disk* && rm -f *_meta.dmp
