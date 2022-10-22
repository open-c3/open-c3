#!/bin/bash
cat node | sort -R |xargs -i{}  bash -c "./install.sh  {} ; echo ok"
