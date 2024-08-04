#!/bin/bash

#prometheus
if [ ! -f prometheus.tar.gz ]; then
wget https://github.com/prometheus/prometheus/releases/download/v2.37.2/prometheus-2.37.2.linux-amd64.tar.gz -O prometheus.tar.gz
fi
