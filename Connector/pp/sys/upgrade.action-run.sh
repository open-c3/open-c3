#!/bin/bash

cd /data/Software/mydan/Connector/pp/sys/upgrade.action || exit 1

ls | sort |xargs -i{} bash -c "./{}"
