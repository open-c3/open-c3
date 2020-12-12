#!/bin/bash 
set -e

export ENVNAME=$1
export USRNAME=$2

cd /data/Software/mydan/Installer/cluster && ./run-parts.sh init
