# 外部服务树缓存

## 简介
```
如果OpenC3的服务树使用了第三方系统，如果第三方系统要下线。
可以通过下面方式把服务树和服务树的资源绑定关系缓存起来。


这个有别与把服务树切换成OpenC3内部服务树。
OpenC3的服务树可以一次配置多个来源。如果是其中一个来源出现系统要下线的情况下使用该方式。

```

## 操作演示

```

下面我们以服务树依赖的是juyun为例。
例子中用的是treemap1和nodeinfo1。同时使用的服务树有效id在900到2000之间。

在操作之前可以看到Connector/config.inix中有如下内容:
=================================================================================
treemap1: https://console.polymericcloud.com/api/keystone/platform/allservicetree
treemapenv1:
  appkey: xxxxxx
  appname: openc3

treemapeid1: [ 900, 2000 ]


nodeinfo1: https://console.polymericcloud.com/api/platform/c3/serviceTree/node/
nodeinfoenv1:
  appkey: xxxxxx
  appname: openc3

nodeinfoeid1: [ 900, 2000 ]

=================================================================================

进到OpenC3容器的/data/Software/mydan/AGENT/scripts/juyuntree目录下。


目录下有treemap.sh和nodeinfo.sh工具。把工具中的xxxxxx更换成对应config.inix配置文件中的appkey。

执行：./make.sh


更新Connector/config.inix文件中的treemap1和nodeinfo1为如下内容:
treemap1: http://localhost:88/api/scripts/juyuntree/treemap/allservicetree
nodeinfo1: http://localhost:88/api/scripts/juyuntree/nodeinfo/

```
