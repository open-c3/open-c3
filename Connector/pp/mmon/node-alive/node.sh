#!/bin/bash

cat /data/Software/mydan/AGENT/conf/promesd.temp | awk -F';' '{print $2 }'|sort|uniq|awk '{print $1, "0"}'
