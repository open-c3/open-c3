# 性能优化/perl/开发工具

# 路径

```
cd /data/open-c3/tools/pd

```

## 安装

```
./init.sh

#只有开发环境需要该模块，暂时不默认打包到容器中
```

## 使用

```
# 启动
./runfast cmd argv ... # 只检查第一层perl，如果system调用了其它命令不进行统计
./rundeep cmd argv ... # 深入检查，如果当前的perl调用了其它perl程序，也一样会检查

# 例
./runfast  /data/Software/mydan/Connector/pp/device/c3mc-device-cat-all --timemachine curr

# 访问报告

打开浏览器访问 http://localhost:8000

```
