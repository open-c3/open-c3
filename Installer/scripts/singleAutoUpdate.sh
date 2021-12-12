#!/bin/bash

logFile=/data/open-c3-data/logs/singleAutoUpdate.log
exec >> $logFile 2>&1 

echo '############################################################'
echo start update ...
date
/data/open-c3/open-c3.sh upgrade SS
echo finish
date
