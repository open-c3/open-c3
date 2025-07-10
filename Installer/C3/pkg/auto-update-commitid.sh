#!/bin/bash

set -e

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )
. $C3BASEPATH/open-c3/Installer/scripts/multi-os-support.sh

cd $C3BASEPATH/open-c3/Installer/C3/pkg || exit

git pull

cat module|grep -v '^#'|c3xargs bash -c "./auto-update-commitid {} || exit 255"
