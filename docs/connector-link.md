# 连接器/对接

如果需要进行连接器对接，需要按照这个文档实现OPEN-C3定义的接口。

# 登录

## 获取用户信息

说明：
```
通过cookie查询用户的信息，配置示例：
http://api.connector.open-c3.org/internal/user/username?cookie=

系统调用的时候会把用户的cookie带入进行查询。

```

调用示例：
```
[root@openc3-srv-docker /]# curl 'http://api.connector.open-c3.org/internal/user/username?cookie=v2aOqUGsQ2mdNrVgynQW73qzWTrXwPlXKgRClIJQdIIZYPPmD7Zz0q2HqhQx3Svd'
{
   "stat" : true,
   "data" : {
      "admin" : 1,
      "showconnector" : 1,
      "company" : "default",
      "user" : "open-c3"
   }
}
```
返回结果说明：

```
stat： true # 查询正常，固定内容。如果系统故障可以返回false
data: 返回查询的内容
data.admin # 0 或 1， 1时表示该用户为管理员，OPEN-C3会通过这个控制前端的显示，有些页面只有管理员可见。
data.showconnector # 0 或 1， OPEN-C3通过这个来控制前端是否显示连接器页面。1为显示。
data.company # 表示公司的名称，为一个字符串。用来控制镜像和密钥共享（密钥和镜像可以选择共享给组织内部）。
data.user # 用户名称，这里最好返回的是用户的邮箱。
```

## 用户登出

说明：
```
通过cookie调用注销用户的登录：
http://api.connector.open-c3.org/default/user/logout?sid=
系统调用的时候会把用户的cookie带入进行调用。
```

调用示例：
```
[root@openc3-srv-docker /]# curl 'http://api.connector.open-c3.org/default/user/logout?sid=v2aOqUGsQ2mdNrVgynQW73qzWTrXwPlXKgRClIJQdIIZYPPmD7Zz0q2HqhQx3Svd'
{
   "stat" : true,
   "info" : "ok"
}
```

## 回调

说明:
```
该地址为当检查到用户没有登录时要跳转的页面，有如下两种格式

格式一：/#/login?callback=

格式二：http://sso.mydomain.org/login?callback=

(格式一不是以http开通，系统会默认带上OPEN-C3当前的域名。)

跳转过程中会把访问OPEN-C3的地址带在后面，如:

http://sso.mydomain.org/login?callback=http://www.open-c3.org/#/connector/config/123

```

## cookie名

平台用的cookie名称。

# 服务树

## 用户服务树

说明：
```
通过cookie查询用户的服务树信息，配置示例：
http://api.connector.open-c3.org/default/tree

系统调用的时候会把用户的cookie带入进行查询。
```

调用示例：
```
[root@openc3-srv-docker /]# curl 'http://api.connector.open-c3.org/default/tree?cookie=j8wKymLzyeJGT0GLIF4QIDLgRWo8vD3Kk7Kjcjsvw0gHG68U9kKGfxDW0xdtGWtK'
{
   "stat" : true,
   "data" : [
      {
         "children" : [
            {
               "children" : [
                  {
                     "children" : [
                        {
                           "id" : 10,
                           "name" : "c3_demo"
                        }
                     ],
                     "id" : 9,
                     "name" : "opsdev"
                  }
               ],
               "id" : 8,
               "name" : "ops"
            }
         ],
         "id" : 7,
         "name" : "open-c3"
      }
   ]
}
```

## 全量服务树


说明：
```
通过appname、appkey查询平台的全量服务树。配置示例：
http://api.connector.open-c3.org/default/tree/map
```

调用示例：
```
[root@openc3-srv-docker /]# curl -H 'appname: jobx' -H 'appkey: 14318225215653259055111884215373' http://api.connector.open-c3.org/default/tree/map
{
   "stat" : true,
   "data" : [
      {
         "id" : 7,
         "name" : "open-c3",
         "update_time" : "0000-00-00 00:00:00",
         "len" : 1
      },
      {
         "update_time" : "0000-00-00 00:00:00",
         "len" : 2,
         "id" : 8,
         "name" : "open-c3.ops"
      },
      {
         "update_time" : "0000-00-00 00:00:00",
         "len" : 3,
         "name" : "open-c3.ops.opsdev",
         "id" : 9
      },
      {
         "name" : "open-c3.ops.opsdev.c3_demo",
         "id" : 10,
         "update_time" : "0000-00-00 00:00:00",
         "len" : 4
      }
   ]
}
```

## 服务树资源

说明：
```
通过appname、appkey查询指定服务树节点机器资源。配置示例：
http://api.connector.open-c3.org/default/node/api/

查询过程中会在末尾添加查询的服务树节点号。
```

调用示例：
```
[root@openc3-srv-docker /]# curl -H 'appname: jobx' -H 'appkey: 14318225215653259055111884215373' http://api.connector.open-c3.org/default/node/api/0 
{
   "data" : [],
   "stat" : true
}
[root@openc3-srv-docker /]# curl -H 'appname: jobx' -H 'appkey: 14318225215653259055111884215373' http://api.connector.open-c3.org/default/node/api/10
{
   "stat" : true,
   "data" : [
      {
         "id" : 0,
         "type" : "idc",
         "exip" : "",
         "inip" : "10.60.77.61",
         "name" : "10.60.77.61"
      },
      {
         "inip" : "10.60.77.62",
         "name" : "10.60.77.62",
         "exip" : "",
         "id" : 1,
         "type" : "idc"
      },
      {
         "exip" : "",
         "type" : "idc",
         "id" : 2,
         "inip" : "10.60.77.75",
         "name" : "10.60.77.75"
      }
   ]
}
```

## 权限控制

```
权限点分两种类型，一种是和服务树相关，另一种是服务树无关。

服务树接口示例：
http://api.connector.open-c3.org/default/auth/point

服务树无关:
http://api.connector.open-c3.org/default/auth/point?point=$point&cookie=$cookie

服务树相关:
http://api.connector.open-c3.org/default/auth/point?point=$point&treeid=$treeid&cookie=$cookie

```

权限点：
```
    #级别说明： 0=> 登录用户 1 => 研发 2 => 运维 3 => 管理员

    # 全局权限点
    my %pointG = (
        openc3_job_root          => [          3 ], # job管理员
        openc3_jobx_root         => [          3 ], # jobx管理员
        openc3_ci_root           => [          3 ], # ci管理员
        openc3_agent_root        => [          3 ], # agent管理员
        openc3_connector_root    => [          3 ], # connector管理员
    );

    # 服务树相关权限点
    my %pointT = (
        openc3_job_read          => [ 0, 1, 2, 3 ], # 读取job的信息
        openc3_job_write         => [       2, 3 ], # 修改job的配置
        openc3_job_delete        => [       2, 3 ], # 删除job的配置
        openc3_job_vssh          => [       2, 3 ], # 使用虚拟终端
        openc3_job_vsshnobody    => [    1, 2, 3 ], # 使用nobody用户的虚拟终端
        openc3_job_control       => [    1, 2, 3 ], # 操作job

        openc3_jobx_read         => [ 0, 1, 2, 3 ], # 读取jobx的信息
        openc3_jobx_write        => [       2, 3 ], # 修改jobx的配置
        openc3_jobx_delete       => [       2, 3 ], # 删除jobx的配置
        openc3_jobx_control      => [    1, 2, 3 ], # 操作jobx

        openc3_ci_read           => [ 0, 1, 2, 3 ], # 读取ci的信息
        openc3_ci_write          => [       2, 3 ], # 修改ci的配置
        openc3_ci_delete         => [       2, 3 ], # 删除ci的配置
        openc3_ci_control        => [    1, 2, 3 ], # 操作ci

        openc3_agent_read        => [ 0, 1, 2, 3 ], # 读取agent的信息
        openc3_agent_write       => [       2, 3 ], # 修改agent的配置
        openc3_agent_delete      => [       2, 3 ], # 删除agent的配置

        openc3_connector_read    => [ 0, 1, 2, 3 ], # 读取connector的信息
        openc3_connector_write   => [       2, 3 ], # 修改conector的配置
        openc3_connector_delete  => [       2, 3 ], # 删除connector的配置
    );

```

调用示例：
```
[root@openc3-srv-docker /]# curl 'http://api.connector.open-c3.org/default/auth/point?point=openc3_job_read&cookie=j8wKymLzyeJGT0GLIF4QIDLgRWo8vD3Kk7Kjcjsvw0gHG68U9kKGfxDW0xdtGWtK'
{
   "data" : 1,
   "stat" : true
}
[root@openc3-srv-docker /]# curl 'http://api.connector.open-c3.org/default/auth/point?point=openc3_job_read&treeid=10&cookie=j8wKymLzyeJGT0GLIF4QIDLgRWo8vD3Kk7Kjcjsvw0gHG68U9kKGfxDW0xdtGWtK'
{
   "data" : 1,
   "stat" : true
}
```

返回结果说明：

```
stat： true # 查询正常
data: 是否有权限，1为有权限，0为无权限
```

# 消息出口

消息出口需要appname和appkey完成验证【添加http的Header】。

## 邮件
```
配置的地址示例:
http://api.connector.open-c3.org/default/mail

调用方式：POST

参数
user：用户名，接口需要自己查询对应的用户的邮箱地址
title: 邮件标题
content: 邮件内容
```

返回：{ stat： true }

## 短信

```
配置的地址如下:
http://api.connector.open-c3.org/default/mesg

调用方式：POST

参数
user：用户名，接口需要自己查询对应的用户的手机号
mesg: 短信内容
```

返回：{ stat： true }

## 语音

```
配置的地址如下:
http://api.connector.open-c3.org/default/mesg
#使用内置是和短信接口一样

调用方式：POST

参数
user：用户名，接口需要自己查询对应的用户的手机号
mesg: 语音内容
```

返回：{ stat： true }


# 外部辅助审批

用于辅助审批，如有OA系统，可以进行OA审批对接。

可以缺省，缺省情况下说明无外部审批功能。

## 审批接口

```
审批接口示例： http://api.connector.open-c3.org/connectorx/approval

需要实现两个调用，GET和POST，POST用于提交审批，GET用于查询审批状态。

方法：POST
参数
content： 审批内容
submitter： 提交人
approver： 审批人
返回 { stat: true, data: $uuid } #其中$uuid为外部系统的审批单号


方法：GET
参数：uuid
返回{ stat: true, data: { status: $status, reason: 'null' } } 
其中$status 为审批单据的状态，状态可以为agree（同意）、refuse（拒绝）、unconfirmed（未审批）
```


# 其他

```
连接器使用的HTTP Header进行验证的部分，在前端页面上不是每一个都可以进行配置，
如果前端上没有进行显示，可以直接修改配置文件/data/open-c3/Connector/config.inix。

可以参考下面配置：

cookiekey: sid
pmspoint: http://console.jy.com/api/keystone/platform/permission
pmspointenv:
  appkey: kkk
  appname: ad

ssocallback: http://console.jy.com/account/login?from=openc3&redirect=http://openc3.org/api/connector/connectorx/setcookie?c3redirect=
ssochpasswd: http://console.jy.com/setting/personalGroup/myprofile
ssologoutaddr: http://console.jy.com/account/login?from=openc3logout&redirect=http://openc3.org/api/connector/connectorx/setcookie?c3redirect=http://openc3.org
ssousername: http://console.jy.com/api/keystone/platform/user?cookie=
ssousernameenv:
  appkey: kkk
  appname: ad

usertree: http://console.jy.com/api/keystone/platform/servicetree
usertreeenv:
  appkey: kkk
  appname: ad

nodeinfo: http://console.jy.com/api/platform/c3/serviceTree/node/
nodeinfoenv:
  appkey: kkk
  appname: ad

treemap:  http://console.jy.com/api/keystone/platform/allservicetree
treemapenv:
  appkey: kkk
  appname: ad

usermail: http://api.connector.open-c3.org/default/mail
usermailenv:
  appkey: c3random
  appname: jobx

usermesg: http://api.connector.open-c3.org/default/mesg
usermesgenv:
  appkey: c3random
  appname: jobx

上面配置中使用到了http://openc3.org/api/connector/connectorx/setcookie接口进行cookie的单独处理。

把http://openc3.org改成本服务的地址。
把http://console.jy.com改成提供连接器接口的地址。
在页面上重新保存不会影响多出来的参数。

关于登出接口，如果有ssologoutapi，会使用该接口进行api调用进行登出，
如果没有ssologoutapi而是配置了ssologoutaddr，会通过重定向到ssologoutaddr进行登出。
如果ssologoutapi和ssologoutaddr都没有系统会报错。
```

## 资源释放

连接器中的服务树被外部系统接管后，服务树节点的删除要询问OPEN-C3系统该节点是否可以删除，从而保证系统一致。

询问方法:
```
http://open-c3.my.domain/api/connector/release?id=服务树节点id
接口会返回两种情况，都为字符串，分别为： true 、 false 【其中true表示服务树可以释放可以删除，false表示不能删除】

```
