#!/bin/bash
set -ex

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )
. $C3BASEPATH/open-c3/Installer/scripts/multi-os-support.sh

cd $C3BASEPATH/open-c3/Installer/C3/pkg/golang-build-tmp || exit

find $C3BASEPATH/open-c3/Connector/pp -name golang-build.sh|sed "s/\/golang-build.sh$//"|c3xargs bash -c "echo golang build {} && cd {} && ./golang-build.sh"

mkdir -p _tempdata/open-c3/tmp/golang-build/tmp/
rsync -av /data//open-c3/tmp/golang-build/tmp/ _tempdata/open-c3/tmp/golang-build/tmp/
mv _tempdata tempdata
