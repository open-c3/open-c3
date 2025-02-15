#!/bin/bash

cd /data/Software/mydan/Connector/pp/sys/cron.hourly || exit 1

ls | grep '^[0-9]\+\..*' | sort -V|xargs -i{} bash -c "./{}"
