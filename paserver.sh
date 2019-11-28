#!/bin/bash

###############################################################
# Copyright (C) 2019 Duall Sistemas Ltda.
###############################################################

paserver -scratchdir=/home/paserver -unrestricted -password= -config=/etc/paserver.config

while sleep 10; do
    ps aux | grep paserver | grep -q -v grep
    PA_SERVER_STATUS=$?
    echo $PA_SERVER_STATUS
    if [ $PA_SERVER_STATUS -eq 0 ]; then
        echo "Complete!"
        exit 1
    fi
done
