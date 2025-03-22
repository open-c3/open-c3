#!/bin/bash

# 获取当前时间戳（以秒为单位）
current_time=$(date +%s)

# 105天的秒数（约105天）
three_months=$((105 * 24 * 60 * 60))

# 遍历所有容器
docker ps -a --format "{{.ID}}\t{{.Names}}" | while read -r container_id container_name; do
    # 检查容器名称是否符合指定格式
    if [[ $container_name =~ ^ci_build_id_[0-9]+_id\..+$ ]]; then
        # 获取容器的最后状态变化时间
        state_changed_at=$(docker inspect --format='{{.State.StartedAt}}' $container_id)
        
        # 如果容器从未启动过，使用创建时间
        if [ "$state_changed_at" = "0001-01-01T00:00:00Z" ]; then
            state_changed_at=$(docker inspect --format='{{.Created}}' $container_id)
        fi
        
        # 将状态变化时间转换为时间戳
        container_time=$(date -d "$state_changed_at" +%s)
        
        # 计算时间差
        time_diff=$((current_time - container_time))
        
        # 如果时间差大于105天，删除容器
        if [ $time_diff -gt $three_months ]; then
            echo "Removing container $container_id (name: $container_name, last state change: $state_changed_at)"
            docker rm $container_id
        fi
    fi
done

