#!/bin/bash
export PATH=$PATH:/usr/local/bin
export C3DEBUG=1

cat /data/open-c3-data/spotx.conf \
  | grep ^[0-9]*:$ \
  | awk -F: '{print $1}' \
  | xargs -i{} -P 10 bash -c "c3mc-spotx-run {} 2>&1|c3mc-base-log-addtime >> /var/log/spotx.{}.log"
