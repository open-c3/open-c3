# 安全/访问控制


Open-C3的前端是通过nginx提供服务的，如果您想对访问进行ip限制，可以在 /data/open-c3-data/nginx.conf/allow.conf 添加控制策略。


/data/open-c3-data/nginx.conf/allow.conf文件的例子:
```
allow 10.10.10.1;
allow 10.10.10.2;
allow 10.10.10.3;
allow 10.10.10.4;
allow 10.10.10.5;
allow 10.10.10.6;

deny all;
```

注: 正常情况下，您的服务如果部署在公有云上，直接通过云上的ACL来控制即可。
