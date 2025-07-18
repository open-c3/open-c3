#!/bin/bash

export PATH=$PATH:/usr/sbin
# 检查 nginx 是否在运行
if ! ps -ef | grep "nginx: master process" | grep -v grep > /dev/null; then
    echo "nginx 未运行，尝试启动..."
    nginx

    # 检查是否启动成功
    if ps -ef | grep "nginx: master process" | grep -v grep > /dev/null; then
        echo "nginx 启动成功"
    else
        echo "nginx 启动失败"
    fi
else
    echo "nginx 正在运行，无需启动"
fi
