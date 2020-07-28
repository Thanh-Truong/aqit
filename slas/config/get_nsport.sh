#!/bin/bash

# Default Amos2 nameserver port
(( port=35021 ))

# Silently (>> /dev/null) see if the port is free, 
# otherwise increase counter to find a free port
if [ "$(uname)" == "Darwin"  ]; then
# Special test for Mac OS X platform  
    while lsof -n -i4TCP:$port | grep LISTEN >> /dev/null
    do
	(( port += 1 ))
    done    
else
    while netstat -antu | grep $port >> /dev/null
    do
	(( port += 1 ))
    done    
fi

echo $port
