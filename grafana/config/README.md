# 监控/grafana/邮件配置

```
一般情况下grafana是管理员【c3的管理员角色用户】可以登陆，普通用户进行查看。

但是有的公司可能会开放grafana的权限给研发自己配置看板。

grafana添加用户是基于邀请的，通过邮件进行邀请。这时候就需要配置一下smtp。

目录下有smtp的例子，主要配置的是smtp的字段和root_url【发送邮件的时候会有root_url字段的内容，让用户点击跳转到平台上】

1.修改好本地的 grafana.ini 文件。可以查看grafana.smtp.ini 的例子。
2.拷贝到容器中
docker cp grafana.ini openc3-grafana:/etc/grafana/grafana.ini 
3.重启容器
docker restart openc3-grafana

【注：要保证grafana.ini文件的内容是正确的，c3 reborn的时候会直接使用这个文件】
```
