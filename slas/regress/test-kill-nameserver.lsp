(osql "
      register('Test-kill-nameserver');
      kill_all_peers();
      raw_unregister_me();")
(sleep 0.5)
(print "Kill nameserver !!!!")
(socket-send '(quit) (open-nameserver-socket)) ;; kill the peer
(sleep 0.5) ;; Make sure message sent
(quit) ;; Kill me 
