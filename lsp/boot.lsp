(cond (_mexima-enabled_       
       (if (null _mexima-new-index-rewriter_)
	   (with-directory "." (load  "boot-aqit.lsp"))
	 (with-directory "." (load  "boot-aqit-1.lsp")))
       (setq *enable-aqit* t)))
