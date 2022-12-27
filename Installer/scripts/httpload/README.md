# 接口简单压测,测试接口稳定性

注: 测试服务在restart和reload过程中接口的稳定性

## 安装

```
./init.sh

#安装完成后，当前目录会有二进制工具http_load
```

# 使用

```
./http_load -p 10 -s 60 url.txt # 10个并发测试60秒
```
