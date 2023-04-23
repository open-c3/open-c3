# 第三方应用/keycloak

# 安装 & 启动

```
cd /data/open-c3/Connector/pp/thirdparty/keycloak

./init.sh  # 初始化

./start.sh # 启动服务


# 需要的时候 可以通过./stop.sh停止服务， 通过./restart.sh 重启服务。

```

# 常见错误

## https 问题

默认会提示 we are sorry, https required.这个是由于安全限制导致的登录失败，在用https的域名访问是不会出现的，如果一定要用IP访问，可以通过下面的命令取消

```

docker exec -it openc3-keycloak bash 
cd /opt/jboss/keycloak/bin 
./kcadm.sh config credentials --server http://localhost:8080/third-party/keycloak/auth --realm master --user admin 
./kcadm.sh update realms/master -s sslRequired=NONE
```


## 重启异常

如果服务启动失败，可以尝试去掉启动脚本中的如下两个参数。

  -e KEYCLOAK_USER=admin 

  -e KEYCLOAK_PASSWORD=admin 
