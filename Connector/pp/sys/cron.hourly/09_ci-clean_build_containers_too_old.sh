#!/bin/bash

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker。"
    exit 1
fi

# 获取磁盘使用率
get_disk_usage() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# 删除最旧的容器
delete_oldest_container() {
    # 获取所有以 ci_build_id 开头的容器，按创建时间排序（最旧的在前）
    oldest_container=$(docker ps -a --filter "name=^ci_build_id" --format "{{.ID}} {{.Names}} {{.CreatedAt}}" | sort -k3 | head -n 1 | awk '{print $1}')
    
    if [ -n "$oldest_container" ]; then
        echo "正在删除最旧的容器: $oldest_container"
        echo docker rm -f "$oldest_container"
        docker rm -f "$oldest_container"
    else
        echo "没有找到以 ci_build_id 开头的容器。"
        exit 0
    fi
}

# 主逻辑
echo "检查磁盘空间利用率..."
disk_usage=$(get_disk_usage)
echo "当前磁盘利用率: ${disk_usage}%"

# 如果磁盘利用率超过 90%，开始删除容器
while [ "$disk_usage" -gt 90 ]; do
    echo "磁盘利用率超过 90%，开始删除最旧的容器..."
    delete_oldest_container

    # 重新获取磁盘利用率
    disk_usage=$(get_disk_usage)
    echo "删除后磁盘利用率: ${disk_usage}%"
done

echo "磁盘利用率已降至 90% 以下，操作完成。"

