#! /bin/sh
###############################################################
# Copyright (C) 2019 Duall Sistemas Ltda.
###############################################################

set -e

docker build --force-rm -t paserver .

docker run -p 9090:9090 -p 64211:64211 -v $(pwd)/bin:/home/paserver -dt paserver
