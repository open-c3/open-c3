# 开发环境/前端开发

OPEN-C3的前端是通过angularjs进行的开发。下面提供了两个方式来准备开发环境。
```
如果是前端工程师，建议使用“纯前端工程师”的方式。
如果是前后端都进行开发的工程师，建议使用“全栈开发的方式”。
```

# 纯前端工程师

方法1:
```
1. OPEN-C3代码中的c3-front为前端代码，根据c3-front/README.md中的描述准备开发环境。
2. 绑定本地hosts文件，把域名open-c3.org指向后端服务器地址，如：10.10.10.1 open-c3.org
```

方法2:(通过docker)
```
mkdir c3-www
cd c3-www
git clone https://github.com/open-c3/open-c3
git clone https://github.com/open-c3/open-c3-dev-cache
rsync -av open-c3-dev-cache/c3-front/ open-c3/c3-front/
docker run -it -v `pwd`/open-c3/c3-front/:/code  -p 8080:3000 --add-host=open-c3.org:10.10.10.10 openc3/gulp gulp serve
#注 上一条命令的8080是本地监听的端口，通过访问http://localhost:8080 即可访问前端服务。
#10.10.10.10为后端Open-C3服务的地址
```

# 全栈开发

1. 在本地安装OPEN-C3[单机版](/单机版安装/README.md)

2. 

```
运行下面命令启动前端开发环境。

/data/open-c3/Installer/scripts/dev.sh start 10.10.10.10(open-c3 api IP)

启动后会多一个docker实例openc3/gulp。通过3000端口进行访问。直接修改c3-front目录中的文件即可实时生效。
```
