# 监控/开发新资源监控的步骤 

添加一个资源类型监控的步骤

下面以mongodb为例

```
第一步：
    添加测试数据到CMDB中。 添加测试服务的容器启停工具。: /data/open-c3/AGENT/monitor/mongodb-query/dev

第二步:
    CMDB 添加连接mongodb的的账号管理

    授权
        mkdir /data/open-c3-data/device/auth/mongodb.auth
        touch /data/open-c3-data/device/auth/mongodb.auth/open-c3

    CMDB 可以编辑mongodb账号
        /data/open-c3/c3-front/src/app/pages/device/data/detail.html
        /data/open-c3/AGENT/lib/api/device.pm

第三步:
    添加摄取mongodb资源的工具

        c3mc-device-ingestion-mongodb

        在容器里面执行一下 c3mc-device-ingestion-mongodb 7 看数据是不是正常的.
        测试的数据放到了服务树open-c3下，服务树id是7.所以测试的时候查看一下7号服务树。

第四步:
    生成监控对象给prometheus

    修改: c3mc-server-agent promesd
    添加: c3mc-mon-mongodbsd-format

    生成了文件： cat /data/Software/mydan/prometheus/config/openc3_mongodb_sd_v3.yml

第五步:

   prometheus进行监控数据采集

       /data/open-c3/prometheus/config/prometheus.example.yml
       /data/open-c3/prometheus/config/prometheus.yml

   prometheus的targets页面能看到采集任务

第六步:
   添加mongodb-query 接口
      添加： /data/open-c3/AGENT/server/mysqlquery
      添加： /data/open-c3/AGENT/agent.mon/lib/OPENC3/MYDan/MonitorV3/MongodbQuery.pm
      修改： /data/open-c3/AGENT/tools 中的reload, start, stop 脚本，启动接口
      修改： /data/open-c3/AGENT/config/api.agent.x.x.conf.Template
      /data/open-c3/JOBX/code/server/monitor 的 agent_supervisor 加1

      prometheus采集的监控数据的url有数据了，不在是404. http://xxx/api/agent/v3/mongodb/metrics/10.10.10.10:27017

第七步:
    启动采集容器

    测试启动服务
       添加： c3mc-mon-mongodb-v3-exportermaker
       测试启动：find /data/open-c3-data/mongodb-exporter-v3/cache/ -type f -mmin -60 | ./c3mc-mon-mongodb-v3-exportermaker

       添加： c3mc-mon-mongodb-v3-exporterclean
       测试清理: find /data/open-c3-data/mongodb-exporter-v3/cache/ -type f -mmin -60 | ./c3mc-mon-mongodb-v3-exporterclean

       添加： c3mc-mon-mongodb-v3-exportercheck 测试配置变更清理

       c3mc-server-agent extend-exporter 启动上面三个任务


第八步:
    为mongodb生成proxy和carry数据
       添加Connector/pp/c3mc-mon-carry-mongodb
       c3mc-server-agent carry 添加mogodb部分

第九步:
    把验证后的代码打tag，生成一个allinone镜像，用于代理使用。


第十步:
    /data/open-c3/Installer/C3/mongodb-query 添加代理镜像构建工具。

```

docker run -it  -p 9216:9216 -p 17001:17001  percona/mongodb_exporter:0.20 --mongodb.uri mongodb://root:123456@10.10.10.10
