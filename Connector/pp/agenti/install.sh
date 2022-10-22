#!/bin/bash

IP=$1

scp openc3.agent.20191021100002.Linux.x86_64 $IP:/tmp/
scp openc3_agent_install.sh                  $IP:/tmp/

ssh -tt $IP "cd /tmp && sudo ./openc3_agent_install.sh"
ssh -tt $IP "cd /tmp && sudo setsid /opt/mydan/dan/bootstrap/bin/bootstrap --start"
