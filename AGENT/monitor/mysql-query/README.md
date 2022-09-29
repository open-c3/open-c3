# mysql监控

## 提取监控资源

在需要让系统识别出mysql的资源下面存放提取文件的配置，文件名为（ ingestion-mysql.yml ）

如: /data/open-c3-data/device/curr/database/huawei-rds/ingestion-mysql.yml 

文件内容如下:
```
addr: [ 'private_ips.0', 'port' ]                  # 这里描述的是ip地址和端口，如果CMDB中没有一个字段包含ip和端口信息，则需要两个字段进行拼装
#auth: [ 'account' ]                               # 从CMDB字段中获取,登录数据库的账号和密码，用“:”分隔
#auth: [ 'dbuser','dbpass' ]                       # 从CMDB字段中获取, 如果登录数据库的账号和密码是CMDB中的两个字段，这里写两个字段
auth: root:abc1234                                 # CMDB中没有mysql的账号信息，所有资源是同一个登录账号
#authfile: /data/open-c3-data/device/curr/database/huawei-rds/authfile.dat # 账号信息在一个外部文件中。文件格式下面内容会描述.
#authpath: /data/open-c3-data/device/auth/mysql    # 从目录中获取账号，每个资源对应一个文件，文件中有账号。可以和CMDB进行联动。
tree: '服务树'                                     # CMDB中存放服务树信息的字段
type: huawei-rds                                   # 给资源一个分类，这个字符串可以随意内容,非CMDB字段。

```
外部账号信息：

```
# cat /path/authfile.dat
172.26.0.8:3306;root:abc123
10.60.77.73:3306;root:123456
```

## 安装代理

系统提取到mysql资源后，会根据代理情况把请求打到代理机上，代理机需要运行本目录下的如下脚本管理服务。代理服务会根据查询的资源启动采集容器。
```
./init.sh    # 初始化，在第一次安装的时候执行
./start.sh   # 启动服务
./stop.sh    # 停止服务
```

不需要代理的部分请求会打到c3主服务容器内部。由内部服务拉起采集容器。
