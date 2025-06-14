# Agent/自动安装


## 什么情况下使用它
```
Open-C3的Agent会在所有的主机上运行，一般情况下，Open-C3的Agent会直接打到镜像里面，或者开机自动初始化。来确保每个机器都安装了Open-C3的Agent。

但是有如下情况可以使用这个工具自动安装Agent：

1. Open-C3是后安装的，线上的机器需要批量安装Agent
2. 担心可能会有Agent漏安装，本工具会自动检测和安装

```

## 使用方式

```

1. 配置Open-C3的地址到addr文件中，格式参考: addr.example
cat addr.example 
http://www.open-c3.online

2. 工具是通过ssh命令连接机器进行安装的，把线上机器的sshkey或者密码保存到 secret 目录下。


例:
# ll secret/
total 120
-rw------- 1 root root 1704 Jun 10  2024 aliyun_prod.pem
-rw------- 1 root root 1675 Jun 10  2024 hw-hongkong.pem
-rw-r--r-- 1 root root    5 Jun 14 17:29 hw-hongkong.pem.username
-rw-r--r-- 1 root root    8 Jun 10  2024 idc1.passwd
-rw-r--r-- 1 root root   11 Jun 10  2024 idc2.passwd
-rw-r--r-- 1 root root   11 Jun 10  2024 idc2.passwd.username

说明:

secret 目录下有三种类型的文件：

1. password 后缀的文件，里面保存的是ssh登陆的密码
2. username 后缀的文件，里面是保存登陆的用户名，这个可以是多行，每一行是一个用户
2. 其他文件，被识别成ssh登陆的key


默认情况下会用root用户进行登陆。 如果某个key，不论是密码的形式还是sshkey的形式，比如文件名是 foo.pem ，如果存在 foo.pem.username 
那么在尝试用foo.pem登陆的时候，就会使用foo.pem.username 里面的用户名进行连接，如果存有多个用户名，会每个都试一下。

3. 配置哪个网段使用哪个key登陆

配置config.txt 文件，描述什么网段使用什么前缀的key，如果没有定义，会尝试所有的key。 

例:

# cat config.txt.example 
172.13,172.12,172.123,10.161:bus
10.111,10.112,10.113:hk
10.5,10.13,10.14,172.21:ucloud
10.111:aliyun
10.20:idc

说明:

1.文件中没有任何空字符。
2.文件中描述的都是 /16网段的IP， 比如 "10.20,10.30:idc",
    意思是 10.20.0.0/16 和 10.30.0.0/16 的网段，使用idc前缀得文件，
    结合上文的例子，会匹配到 idc1.password 和 idc2.password ，会尝试用这两个密码进行连接。
3.如果连接的机器IP在这个文件里面没有定义，会尝试所有的key，这样会慢一点。如果确定前缀的可以写到配置文件中。

```
