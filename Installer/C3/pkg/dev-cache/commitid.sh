#!/bin/bash

# 创建目录（如果不存在）
mkdir -p ../temp
cd ../temp

# 判断是否需要克隆仓库或更新
if [ ! -d "open-c3-dev-cache" ]; then
    git clone https://github.com/open-c3/open-c3-dev-cache.git
fi

cd open-c3-dev-cache

# 拉取最新代码
git pull

# 获取最新提交的ID
ID=$(git log -1 --format=%H)

echo https://github.com/open-c3/open-c3-dev-cache/commit/$ID
