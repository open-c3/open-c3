#!/bin/bash

cd /data/Software/mydan/prometheus/config/fping-v2 || exit

./make > ../targets/fping-v2.yml 
../../bin/reload.sh
