# 服务树/整理

如果在服务树调整阶段。需要大量的调整服务树。提供了如下命令对服务树的名称进行批量调整

```
c3mc-base-tree-dump |sed 's/_/-/g' |c3mc-base-tree-load
c3mc-base-tree-dump |sed 's/;open-c3/;open-c4/' | ./c3mc-base-tree-load 

```

注: 该工具只针对使用C3服务树的情况下，它们整理的是c3数据库中的服务树。
