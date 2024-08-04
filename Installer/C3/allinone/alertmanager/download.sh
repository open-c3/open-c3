#!/bin/bash

if [ ! -f alertmanager.tar.gz ]; then
    wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-386.tar.gz -O alertmanager.tar.gz
fi
