# prometheus镜像构建

# 环境准备
```
# 安装promu
curl -s -L https://github.com/prometheus/promu/releases/download/v0.5.0/promu-0.5.0.linux-amd64.tar.gz | tar -xvzf - -C /tmp
cp /tmp/promu-0.15.0.linux-amd64/promu /usr/bin/

mkdir -p /data/open-c3/prometheus/image/code
cd /data/open-c3/prometheus/image/code
git clone git@github.com:open-c3/prometheus.git
```

## 编译
```
cd /data/open-c3/prometheus/image/code/prometheus
promu crossbuild -p linux/amd64
make npm_licenses                                                 #第一次编译时运行一次即可
make common-docker-amd64
docker tag prom/prometheus-linux-amd64:main openc3/prometheus:v1  # 修改成当前要构建的版本号
```

## 编译版本
```
openc3/prometheus:v1 # 消息超时10年
openc3/prometheus:v2 # 消息超时10倍
openc3/prometheus:v3 # debug日志中显示往alertmanager发送的数据
```
