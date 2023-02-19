# 迁移/把C3从集群中迁移到单机版

## 停止CI和定时任务

```
#touch 如下文件，关闭掉ci的自动构建和corntab作业任务的执行。
touch /data/open-c3/Connector/c3.maintain
```

# 挂载线上共享目录

```
mount -t glusterfs 10.10.10.10:/c3smx/c3_master/glusterfs /data/open-c3-data/glusterfs

注: 10.10.10.10:/c3smx/c3_master/glusterfs 为线上集群的共享目录。
```

# 把c3容器重新启动起来

重新启动的容器会把挂载的路径映射到容器内部。

# 替换current文件

通过glusterfs把current文件同步，并替换到新C3

# 更新数据库

```
通过glusterfs把最新的数据库备份文件放到c3的目录下,为了避免干扰，可以把本机无用的删除了.
/data/open-c3-data/backup/mysql

恢复数据库：./databasectrl.sh  recovery 221123.210501
```

# 更新其他数据
```
在master上 dump.sh 在新c3上load.sh # 【工具路径 /data/open-c3/Connector/maintain】

在master dump_log.sh foo 在新c3上load_load.sh foo # 这里如果有多个机器，每个的日志都要同步过来

```
