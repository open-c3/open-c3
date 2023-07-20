#!/bin/bash

/data/Software/mydan/Connector/pp/mmon/serialcall/run 2>&1 | c3mc-base-log-addtime >> /data/open-c3-data/serialcall.log 2>&1
