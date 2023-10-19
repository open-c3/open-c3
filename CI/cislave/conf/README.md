# CI/cislave说明

## 说明
```
如果CI构建的时候，需要支持多个区域的CI slave。
可以根据下面的说明进行cislave配置。

```

## slave上操作(重要,需要先操作)
```
在slave中配置如下文件，用于标识本slave是哪个ip。slave会根据这个信息获取要执行的任务列表。
如果没有对应标识，会被认为是master，会执行master的任务，所有这里一定要安装好slave首先要完成的操作。

cat myname 
10.x.x.103


```

```
在slave上安装master的发布agent。
master会通过agent给cislave推送数据。

```

## master上操作
```

在master机器上配置slave列表文件，用于标识可用的slave列表。c3集群本身用master进行标识。
其中里面的alias字段不是必须的，不配置的情况下和host等同。

# cat slave.yml
- 
  host: 10.60.77.103
  alias: cislave.c3.x.org

在master上配置master信息文件，slave的ci构建结束后可能会触发cd，所以这里需要配置master的信息。

#cat master.yml 
addr: http://10.x.x.73
env:
  appname: jobx
  appkey: xxx


master上会把信息sync给所有的slave，信息包括上面的配置文件和数据库中的相关数据。

```
