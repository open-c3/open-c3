# 阿里云/PAI/报告


## 初始化

```
执行 ./init.sh 安装依赖。
不是每个c3都需要这个功能，暂时不做默认安装。
```

## 设置
```
在文件config.txt中配置要报告的PAI集群

如:
ak sk region clusteruuid1:clusteralias1
ak sk region clusteruuid1:clusteralias1 clusteruuid2:clusteralias2 ...

```

## 消息

```
默认会定时给用户alipai发送IM消息如下：

A800                                 | U.min   | U.avg   | U.max   | M.min   | M.avg   | M.max  
-------------------------------------+-------+-------+-------+-------+-------+-------
Cluster                              | 0.0     | 90.3    | 100.0   | 96.5    | 96.5    | 96.5   
lixxxxxxxxxxxi-xxxxxxxxxxxxxxxxq-0   | 0.0     | 89.1    | 100.0   | 96.5    | 96.5    | 96.5   
lixxxxxxxxxxxi-xxxxxxxxxxxxxxxxq-1   | 0.0     | 91.7    | 100.0   | 96.5    | 96.5    | 96.5   


H800                                 | U.min   | U.avg   | U.max   | M.min   | M.avg   | M.max  
-------------------------------------+-------+-------+-------+-------+-------+-------
Cluster                              | 78.6    | 99.2    | 99.9    | 84.0    | 84.0    | 88.7   
xxxxxxxxxxxxxxa0g-mxxxxxxxxxxxxn-0   | 62.5    | 99.2    | 100.0   | 88.9    | 88.9    | 88.9   
xxxxxxxxxxxxxxa0g-mxxxxxxxxxxxxn-1   | 0.0     | 97.5    | 99.9    | 31.7    | 31.9    | 32.2   
xxxxxxxxxxxxxxa0g-mxxxxxxxxxxxxn-2   | 95.9    | 99.5    | 100.0   | 88.7    | 88.7    | 88.7   
xxxxxxxxxxxxxxa0g-mxxxxxxxxxxxxn-3   | 93.9    | 99.3    | 100.0   | 88.5    | 88.5    | 88.5   
xxxxxxxxxxxxxxa0g-mxxxxxxxxxpbio-0   | 0.0     | 99.1    | 100.0   | 88.6    | 88.6    | 88.6   
xxxxxxxxxxxxxxa0g-mxxxxxxxxxpbio-1   | 93.8    | 99.4    | 100.0   | 88.6    | 88.6    | 88.6   
xxxxxxxxxxxxxxa0g-mxxxxxxxxxpbio-2   | 90.4    | 99.4    | 100.0   | 88.8    | 88.8    | 88.8   


Time: 2023-09-05 00:00:00 ~ 2023-09-05 23:55:00
```
