#!/bin/bash

/data/Software/mydan/Connector/pp/mmon/alertmanagercrontab/run 2>&1 | c3mc-base-log-addtime >> /data/open-c3-data/logs/alertmanagercrontab.log 2>&1
