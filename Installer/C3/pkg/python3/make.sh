#!/bin/bash
set -ex

/app/init/install-python3.sh
/app/init/install-pkg.sh

cd /usr/local
tar -zcvf python3.tar.gz python3

mv python3.tar.gz /app
