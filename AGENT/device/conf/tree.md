# CMDB/默认服务树

## 配置服务树信息来源

```
cat /data/open-c3/AGENT/device/conf/config.copytreecol
sync-huawei-dds: [ 'tag.tree', '_tree_' ]
default: [ 'tag.tree', '_tree_' ]
default-volume: [ 'tag.tree', '_vmtree_', '_tree_' ]

可以通过上述文件配置默认的服务树来源字段，该文件由c3代码进行维护。
如果想自己定义请写到路径/data/open-c3/AGENT/device/conf/config.copytreecol.private

默认情况下，服务树的来源为云上资源的tag（tag.tree）和 内部服务树(_tree_)
磁盘资源服务树来源 云上tag(tag.tree) + 磁盘主机的服务树信息(_vmtree_) + 内部服务树(_tree_)

```

## 配置默认服务树挂载节点

```
cat /data/open-c3/AGENT/device/conf/config.defaulttree 
sync-huawei-dds: _null_
default: _null_

可以通过上述文件配置资源默认的挂载服务树节点。该文件由c3代码进行维护。
如果想自己定义默认挂载路径, 请写到路径/data/open-c3/AGENT/device/conf/config.defaulttree.private

这是一个服务树的格式，如sync-huawei-dds: aa.bb.cc
```
