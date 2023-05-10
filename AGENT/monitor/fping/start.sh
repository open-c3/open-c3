#!/bin/bash

docker run -d --restart=always \
  --name openc3-fping \
  --network c3_JobNet \
  joaorua/fping-exporter fping-exporter --fping=/usr/sbin/fping -c 100
