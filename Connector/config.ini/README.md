# 连接器配置说明

## treemap 

```
treemap: http://xx.xx.xx.xx:8081/v2/tree/treemap
treemapenv:
  appkey: xx
  appname: xx
treemapgrep: [ 4891 ] # 服务树中
treemapeid: [ 4000, 1000000 ]
treemapexstr: ['.foo', '.bar', 'abc']

#配置有OA接口，同时approversync为1时，会对审批状态进行回收.
#即：如果审批是在C3上操作的，审批状态会同步到OA系统中.
approversync: 1
```

## nodeinfo

```
nodeinfo配置的是服务树获取主机资源的api。

现在的资源是可以从cmdb中摄取的。如果不想从外部也不想从内置的服务树资源获取资源，可以配置为 "x" 。
这样获取的时候就会跳过这部分。

```
