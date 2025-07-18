#!/bin/bash

export PATH=$PATH:/usr/sbin
# 检查 crond 是否在运行
if ! ps -ef | grep "\bcrond\b" | grep -v grep > /dev/null; then
    echo "crond 未运行，尝试启动..."
    crond

    # 检查是否启动成功
    if ps -ef | grep "\bcrond\b" | grep -v grep > /dev/null; then
        echo "crond 启动成功"
    else
        echo "crond 启动失败"
    fi
fi
