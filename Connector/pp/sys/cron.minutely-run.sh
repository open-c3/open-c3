#!/bin/bash

cd /data/Software/mydan/Connector/pp/sys/cron.minutely || exit 1

ls | sort |xargs -i{} bash -c "./{}"
