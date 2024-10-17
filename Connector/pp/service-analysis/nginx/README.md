# CMDB/服务分析/nginx


## 默认配置
```
# cat /data/open-c3/Connector/pp/service-analysis/nginx/nginx.node 
nginx /data/apps/nginx/conf/conf.d
nginx /etc/nginx/conf.d
nginx /usr/local/openresty/nginx/conf/conf.d
```

## 自定义配置

```

如果默认的配置不满足需求，可以自定义nginx的采集规则,
配置文件文件路径： /data/open-c3-data/service-analysis/nginx.node

配置文件内容格式:

  文件用空格分隔的三列：

    第一列: 服务树ID、IP地址、"nginx"字样。 其中nginx字样表示服务树节点名称是"nginx"的节点下的机器
    第二列: 采集的nginx配置的路径
    第三列: 配置文件的别名、可以忽略、系统会自动生成


例子:

# cat /data/open-c3-data/service-analysis/nginx.node
nginx /data/apps/nginx/conf/conf.d
nginx /etc/nginx/conf.d
nginx /usr/local/openresty/nginx/conf/conf.d
10.10.10.10 /etc/nginx/conf.d_abc
9123 /etc/nginx/conf.d_abc

```
