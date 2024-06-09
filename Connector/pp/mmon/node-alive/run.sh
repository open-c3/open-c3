#!/bin/bash

cd /data/Software/mydan/Connector/pp/mmon/node-alive || exit 1
./node.sh |./ext-c3agent |./ext-ping-inip|./ext-ping-exip |./ext-tcp-inip 22|./ext-tcp-inip 3389 | ./ext-tcp-exip 22|./ext-tcp-exip 3389 |./format > /data/Software/mydan/Connector/local/node-alive.txt.tmp.$$ && mv /data/Software/mydan/Connector/local/node-alive.txt.tmp.$$ /data/Software/mydan/Connector/local/node-alive.txt
