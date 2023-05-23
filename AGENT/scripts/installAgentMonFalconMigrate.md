# 监控迁移/数据与falcon兼容

```
falcon的agent使用的是1988端口，OpenC3的agent使用的是65110端口。

在迁移过程中，需要部署两个agent，两个agent会各自采集数据。但是有一个数据是比较特殊的，就是本地的采集脚本push到falcon agent本地端口上的数据（1988端口）。

正常的情况下，只要把数据一样的格式上报到1988和65110端口即可。

但是可能falcon已经用了很长一段时间，主机上也有很多的脚本，甚至有本地的二进制程序会push数据到本地的1988端口，这时候全部修改上报逻辑就会很麻烦。


可以通过下面方式进行解决：

curl -L http://your_openc3_addr/api/scripts/installAgentMonFalconMigrate.sh |sudo bash

该脚本安装后，会把原来falcon 1988端口改成1987，然后在1988端口上启动一个服务，当有数据请求1988端口时，会把数据同时提供给1987和65110.
```
