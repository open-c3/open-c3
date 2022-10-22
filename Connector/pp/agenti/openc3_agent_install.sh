#!/bin/bash

ps -ef|grep mydan.bootstrap.master|awk '{print $2}'|xargs -i{} kill {}

sleep 3;

rm -rf /data/mydan /opt/mydan

./openc3.agent.20191021100002.Linux.x86_64

rm -f openc3.agent.20191021100002.Linux.x86_64

/opt/mydan/dan/bootstrap/bin/bootstrap --start
