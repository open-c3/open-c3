# 弹性伸缩/spotx

## 添加配置: /data/open-c3-data/spotx.conf

定时任务配置有的集群，会自动跑起任务，日志在 /var/log/spotx.[集群编号].log

```
70000007:                                                                #k8s集群管理中的凭据编号
  maxcpu: 2000                                                           #大pod的cpu阈值
  maxmem: 3000                                                           #大pod的内存阈值，【cpu和内存都大的时候才算大pod】
  smallrelease: 2500000                                                  #主机上有小pod标签的，整体资源空闲百分比的时候开始回收整理pod主机。
  exclude: [ 'jaeger', 'amazon-cloudwatch', 'default', 'cert-manager' ]  #排除掉部分namespace
  excludeprefix: [ 'kube-', 'monitoring', 'kubestar', 'kube' ]           #根据前缀排除掉namespace
#  debugnode:                                                            #调试节点，如果需要调试，可以添加这个字段，这个字段下的主机才会打标签，其他跳过
#   - ip-10-10-10-1.ec2.internal
#   - ip-10-10-10-2.ec2.internal
```


## 批量添加亲和性

在配置文件/data/open-c3-data/spotx-todo.conf中配置好集群配置，格式和 /data/open-c3-data/spotx.conf 格式一样.

批量给已有的deployment添加亲和性设置
```
c3mc-spotx-affinity-todo 70000007
#命令执行完后会生成两个脚本，一个是批量添加亲和性，一个是批量去掉亲和性设置。
```
