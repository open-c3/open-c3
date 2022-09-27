#!/bin/bash
docker exec -it openc3-prometheus promtool check config /data/prometheus-root/config/prometheus.yml
