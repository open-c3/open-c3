# 监控/ping监控

## 源

### 配置
```
源是发起ping的主机节点。

在 src 目录下，存放源主机分组，每个文件是一个分组，文件每行是个ip或者域名

例子:

[root@open-c3]# ls src
cloud-aws-afs
cloud-huawei-open-c3
[root@open-c3]# cat src/cloud-huawei-open-c3 
openc3-fping
[root@open-c3]# cat src/cloud-aws-afs 
10.10.10.111
10.10.10.112
```

### 在源机器上启动容器
```
docker run -d --restart=always -p 9605:9605 --name openc3-fping joaorua/fping-exporter fping-exporter --fping=/usr/sbin/fping -c 10
```

### ACL

开放访问权限，让Open-C3机器访问源机器的9605端口

## 目标

```
目标是要ping的对象，放在dst目录下，每个文件是一个分组。格式和源一样

```

## 配置采集

```

conf.yml配置着需要采集的任务，是个yaml格式

key是src中源的名称
valus 是个数组，数组中的元素是目标的名称，或者一个正则表达式匹配目标中的名称。
      特殊情况，当value是 '*' 时表示所有目标组

例子:
# cat conf.yml

cloud-huawei-open-c3:       [ '/country/', '/website/', '/cloud/', '/workplace/' ]
cloud-ucloud-ng:            [ '/country/', '/website/' ]
cloud-huawei-afs:           [ '/cloud/' ]
cloud-aws-afs:              [ '/country/' ]
cloud-aliyun-frankfurt:     '*'
```

## 生成普罗米修斯配置文件

```
到容器中该目录下执行 ./make.sh 命令
```

