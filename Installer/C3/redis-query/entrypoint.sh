#!/bin/bash
set -e

/data/Software/mydan/Connector/pp/c3mc-install

/data/Software/mydan/AGENT/tools/../../JOB/bin/supervisor \
  --errname agent.server.extend-exporter \
  --name    agent_supervisor \
  --err     /var/log/open-c3.error.log \
  --cmd     'c3mc-server-agent extend-exporter'  \
  --log     /data/Software/mydan/AGENT/logs/server/extend-exporter

/data/Software/mydan/AGENT/tools/../../JOB/bin/supervisor \
  --errname agent.server.redisquery \
  --name    agent_supervisor \
  --err     /var/log/open-c3.error.log \
  --cmd     /data/Software/mydan/AGENT/server/redisquery \
  --log     /data/Software/mydan/AGENT/logs/server/redisquery

tail -F /var/log/open-c3.error.log 
