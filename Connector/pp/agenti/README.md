# 安装/Agent/批量安装&升级

## 通过发布Agent批量安装和升级监控Agent

```
cd /data/Software/mydan/Connector/pp/agenti  # 进入该目录下执行，安装和升级脚本会访问执行路径下的 .addr 和 .version 文件


把Open-C3的地址写到本目录的 .addr 文件中， 内容如: http://10.10.10.1

把监控Agent的期望版本号写入本目录的 .version 文件中，版本号是一个数字. 如： 23


批量安装监控Agent,执行命令 c3mc-mon-agent-install 。安装的列表为监控系统中up == 0 的机器

批量升级监控Agent,执行命令 c3mc-mon-agent-update 。 升级的列表是Agent版本号小于 .version 中标记的版本。

批量安装falcon兼容程序, 执行命令c3mc-mon-agent-falconmigrate 。升级的列表是程序版本小于 .versionfalconmigrate 的机器。

```

## 在堡垒机上批量安装发布和监控的Agent

```
和上一步一样，进入指定目录，写好 .addr 和 .version 文件。

1. 执行 ./package.sh 打包当前Open-C3的Agent成一个独立的文件。

2. 把本目录拷贝到跳板机上

3. 执行 ./upgrade.sh 把C3中的中的压缩包下载到跳板机的本目录下

4. 把要安装的机器的ip写到跳板机执行目录的 node 文件中。

5. 执行批量安装命令: ./run.sh

```
