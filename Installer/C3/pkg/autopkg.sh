#!/bin/bash

set -e

cd /data/open-c3/Installer/C3/pkg || exit

git pull

cat module|grep -v '^#'|xargs -i{} bash -c "./autopkg {} || exit 255"
