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

#新启动的镜像，可以通过下面命令添加用户用于登录

docker exec openc3-server  c3mc-base-adduser --user open-c3

```
