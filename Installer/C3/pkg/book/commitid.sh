#!/bin/bash

# 创建目录（如果不存在）
mkdir -p ../temp
cd ../temp

rm -rf open-c3.github.io
git clone https://github.com/open-c3/open-c3.github.io.git

cd open-c3.github.io

# 获取最新提交的ID
ID=$(git log -1 --format=%H)

echo https://github.com/open-c3/open-c3.github.io/commit/$ID
