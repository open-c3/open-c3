# 应用市场/AWS marketplace

## 镜像制作

```
制作镜像的步骤：
1. 使用一键安装脚本安装最新版本的Open—C3.
curl https://raw.githubusercontent.com/open-c3/open-c3/v2.6.1/Installer/scripts/single.sh | OPENC3VERSION=v2.6.1 bash -s install
2. 执行下面命令，清理命令历史，ssh key文件等
/data/open-c3/Installer/scripts/AWS-AMI.sh force
```

## 镜像使用

```
#OpenC3默认使用80端口对外提供服务。

#aws中国境内的服务器，要经过备案后80端口才可以访问。如果需要更换端口，可以执行下面的命令（以8090端口为例）

iptables -t nat -A PREROUTING -p tcp --dport 8090 -j REDIRECT --to-port 80

# 注: 正常情况下net转发是打开的，如果端口访问不正常，可以用这个命令打开一下：sysctl net.ipv4.ip_forward=1


#新启动的镜像，可以通过下面命令添加用户用于登录

docker exec openc3-server  c3mc-base-adduser --user open-c3

```

## 使用指南
```
1.通过镜像启动产品
2.使用Web浏览器访问http://<EC2_Instance_Public_DNS>上的应用程序
3.在通过镜像创建机器之后，使用以下命令创建帐户密码：
sudo docker exec openc3-server c3mc-base-adduser --user open-c3
user: open-c3
password: Example "VSfjZDw8qrScgwWgKI"


•  登录系统后，在右上角的“管理”菜单中输入“系统监视器”，即可检查系统的健康状况。
•  关于编程系统凭据和加密密钥的轮换，默认情况下，用户的登录帐户密码有效期为90天，并且在密码有效期剩余15天时，系统会提醒用户更改密码。
•  敏感信息存储位置：
     /data/open-c3-data/auth: 代理的公钥和私钥
     /data/open-c3-data/device/curr/auth: 授权查看资源管理中账户的用户授权文件
     /data/open-c3-data/sysctl.conf: 系统参数配置文件
     /data/open-c3/Connector/config.ini: 系统连接器配置文件
```
