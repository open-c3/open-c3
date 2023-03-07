#!/bin/bash

set -e

if [[ "X$1" == "Xforce" || "X$1" == "X-f" ]];then
    /data/open-c3/open-c3.sh upgrade
else
    /data/open-c3/open-c3.sh upgrade S
fi

/data/open-c3/open-c3.sh sup
/data/open-c3/open-c3.sh dup
