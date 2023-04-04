# 迁移/C3服务

## 说明
```
open-c3部署后，会使用本地的两个目录: /data/open-c3 (程序目录) 和 /data/open-c3-data (数据目录)
正常情况下，只要把这两个目录拷贝到新机器的相同路径下就可以把服务启动到新的机器上。

但是有如下几个问题需要考虑:

  1. 我的网络环境比较复杂，在c3的代理管理中配置了很多代理，包括用来做CICD的代理和监控的代理
     迁移过去的机器网络都是通的吗，怎么做验证。
  2. 我的容器管理中的集群，迁移到新c3后网络是否正常。
  3. 我流水线中使用到的git地址，在新c3中网络是否通。
  4. 我的c3的open-c3-data目录很大(比如：CI构建出来的项目的历史版本的发布包)，数据需要怎么同步
     如果需要关旧c3然后拷贝到新C3后在启动服务，这个时间会比较长，想缩短这个时间避免影响业务使用c3。

为了解决如上描述的几个问题，这里提供了迁移的工具。

```

## 使用方式

```
1. 在新旧c3的机器上部署旧c3的agent，让旧c3可以访问它。【注意：新c3和旧c3部署的都是旧c3的agent】
2. 在新c3中通过一键安装的方式安装单机版c3
2. 在旧c3上执行迁移命令
  /data/open-c3/Connector/migrate/sync --node C3的ip

```

## 需要确认
```
keycloak 还能用吗？
serverless 发布添加白名单，账号ip白名单允许新机器发布.
迁移完后 stop， start服务，然后upgrade一下， 因为依赖模块没有解压到容器中，比如perl的依赖模块，导致它启动不去来。
云监控的部分，DB同步后，可能开启两个,需要注意关闭旧C3的云监控。
```

## 迁移详细步骤

```
# 锁住新C3，设置成维护状态

touch /data/open-c3/Connector/c3.maintain /data/open-c3/Connector/c3.maintain.mon /data/open-c3/Connector/c3.maintain.flow 
c3-restart

# 执行迁移操作

/data/open-c3/Connector/migrate/sync --node C3的ip

# 确认新c3数据库
到新c3上看一下新发现的tag，是不是都是“reason: sys@app c3.maintain”
use ci;
select * from openc3_ci_version order by id desc  limit 10\G;

# 确认配置是否有需要修改的
检查链接器配置，比如消息出口的ip地址是不是要更换。
系统参数中，比如系统备份的地址是不是要更换。

# 追加数据
需要追加同步的是， ci_repo 和 logs日志，这几天构建出来的包和构建日志
/data/open-c3/Connector/migrate/patch --node C3的ip --day 7

# 用网络c3mc中的网络测试工具测试新旧网络
测试网络差异，包括主机代理, git 等。
```
