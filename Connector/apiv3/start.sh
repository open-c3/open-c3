#!/bin/bash
set -e

cd $(dirname $0)

PORT=$1

if [ -z $PORT ];then
    echo Uage: $0 port
    exit 1
fi
export C3_APIV3_PORT="$PORT"

echo " 启动服务..."
exec ./start.py
