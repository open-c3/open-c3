#!/bin/bash
export PATH=$PATH:/usr/local/bin
export C3DEBUG=1
c3mc-spotx-run 2>&1|c3mc-base-log-addtime >> /var/log/spotx.log
