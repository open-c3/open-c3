# 当前支持的公有云

| 云厂商 | 资源同步                                                                                   |
| ------ | ------------------------------------------------------------------------------------------ |
| AWS    | 计算(ec2)、     数据库(rds、redis、memcached、dynamodb)、存储(s3)、         网络(alb、elb) |
| 华为云 | 计算(ecs)、     数据库(rds、redis、dds、nosql)、                            网络(elb)      |
| 腾讯云 | 计算(cvm)、     数据库(cdb、redis、mongodb、sqlserver)、 存储(ckafka、cos)、网络(clb)      |
| 谷歌云 | 计算(vm)、      数据库(rds)                                                                |
| 阿里云 | 计算(ecs)、     数据库(rds、redis)、                     存储(oss)、        网络(slb)      |
| 金山云 | 计算(kec、epc)、数据库(krds、redis)、                    存储(ks3)、        网络(slb)      |


# CMDB 云资源同步

## 说明

本目录下存放云资源同步的插件。

每个插件是一个独立的可执行命令，命令把获取到的云资源输出到标准输出。

输出的格式每一行是一个资源，每一行都是一个json格式的数据。

名称格式：c3mc-cloud-云名称-云资源类型 【例：c3mc-cloud-huawei-rds 】

## 多账号问题

通过 c3mc-cloud-account 工具完成

工具使用方式:

### 方式1

echo "账号名称 插件的参数" | c3mc-cloud-account -p 插件名称

例: echo  "acountname ak sk project_id(可以传None) cn-north-4" | c3mc-cloud-account -p c3mc-cloud-huawei-rds

### 方式2

c3mc-cloud-account -p 插件名称 --account 账号文件

例：c3mc-cloud-account -p c3mc-cloud-huawei-rds --account huawei 

账号文件位置： /data/open-c3/AGENT/device/conf/account/账号文件名

账号文件格式：
```
cat /data/open-c3/AGENT/device/conf/account/huawei 
huawei001 ak1 sk1 None cn-north-4
huawei002 ak2 sk2 None cn-north-4
```
### 多账号处理后的数据内容变化

通过c3mc-cloud-account工具处理完后，原始同步插件返回的数据中多出来一个字段"account", 字段的内容是第一个字段的账号名。

### 注意事项

1. 华为云资源同步。如果传递了 project_id 参数，需要在项目级别配置权限；如果传递了 None，需要在 iam 级别配置权限。
