#!/bin/bash

# 目标软链接路径
TARGET_LINK="/usr/bin/docker"

# 如果 /usr/bin/docker 已存在，则退出
if [ -e "$TARGET_LINK" ]; then
    echo "$TARGET_LINK already exists. No action taken."
    exit 0
fi

# 找到所有匹配 docker_v* 的文件
DOCKER_BINARIES=$(ls /usr/bin/docker_v* 2>/dev/null)

if [ -z "$DOCKER_BINARIES" ]; then
    echo "No docker_v* binaries found in /usr/bin"
    exit 1
fi

# 提取版本号并排序（降序），形如 docker_v26.1.4
BEST_CANDIDATE=""
for BIN in $DOCKER_BINARIES; do
    VERSION=$(basename "$BIN" | sed 's/docker_v//')
    echo "$VERSION $BIN"
done | sort -rV | while read -r VERSION BIN; do
    # 尝试运行该版本 docker 命令
    if "$BIN" version >/dev/null 2>&1; then
        ln -s "$BIN" "$TARGET_LINK"
        echo "Created symlink: $TARGET_LINK -> $BIN"
        exit 0
    else
        echo "Version $VERSION at $BIN not working, skipping..."
    fi
done

if command -v docker >/dev/null 2>&1 && docker version >/dev/null 2>&1; then
    echo "Docker command is available."
    exit 0
else
    echo "No working docker binary found."
    exit 1
fi
