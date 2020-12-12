#!/bin/bash
set -e

PROC=$(ps -ef|grep "nginx: master proces[s]"|wc -l)
test "X0" == "X$PROC" || exit 0 

service nginx start
