#!/bin/bash

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker。"
    exit 1
fi

# 获取所有容器的 ID 和名称
containers=$(docker ps -a --format "{{.ID}} {{.Names}}")

if [ -z "$containers" ]; then
    echo "没有容器存在。"
    exit 0
fi

# 遍历每个容器
while IFS= read -r container; do
    # 提取容器 ID 和名称
    container_id=$(echo "$container" | awk '{print $1}')
    container_name=$(echo "$container" | awk '{print $2}')

    # 使用 docker inspect 获取容器的存储路径
    merged_dir=$(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' "$container_id" 2>/dev/null)
    upper_dir=$(docker inspect --format='{{.GraphDriver.Data.UpperDir}}' "$container_id" 2>/dev/null)

    # 检查路径是否存在
    if [ -d "$merged_dir" ]; then
        # 如果 MergedDir 存在，计算其磁盘使用量
        disk_usage=$(du -sh "$merged_dir" 2>/dev/null | awk '{print $1}')
    elif [ -d "$upper_dir" ]; then
        # 如果 MergedDir 不存在（停止的容器），计算 UpperDir 的磁盘使用量
        disk_usage=$(du -sh "$upper_dir" 2>/dev/null | awk '{print $1}')
    else
        # 如果路径都不存在，无法获取磁盘使用量
        disk_usage="无法获取"
    fi

    echo "容器名称: $container_name (ID: $container_id) 磁盘使用量: $disk_usage"
done <<< "$containers"
