#!/bin/bash

cd /data/Software/mydan/Connector/pp/sys/cron.daily || exit 1

ls | sort |xargs -i{} bash -c "./{}"
