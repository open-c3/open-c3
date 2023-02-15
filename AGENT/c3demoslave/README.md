# 演示环境虚拟节点

```
本工具给C3添加10个slave。slave中安装了发布和监控的agent。
机器ip以172开头。start完后slave会默认添加到服务树[7,8,9,10]中。
```

## 启动方式
```
1. cp env.example .env
2. 把c3的地址写入 .env
3. ./start.sh 
```

## 停止方式
```
./stop.sh
```
