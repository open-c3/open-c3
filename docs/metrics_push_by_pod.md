# 监控/容器中的pod上传监控数据


C3的监控agent支持push方式上传数据，agent部署在node节点上，pod需要知道主机节点的ip，可以通过下面方式进行配置
```
    spec:
      containers:
      - env:
        - name: NODE_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.hostIP

```
