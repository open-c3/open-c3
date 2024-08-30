# 功能介绍
<p>该脚本主要功能为查看k8s集群各pod控制器是否开启了探针健康状态监测,并监测对应image是否在华为云SWR仓库</p>

## 使用方法


```
Usage of ./c3mc-service-analysis-get-k8s-health:
  -cluster string
    	Name of the cluster (default "default")
  -kubeconfig string
    	Path to kubeconfig file

脚本接受两个参数,
  -kubeconfig  kubernetes kubeconfig文件路径
  -cluster     集群名称,可接受变量

配置文件config.yaml内四个参数
ak: 华为云国内账号ak
sk: 华为云国内账号sk
hkprojectId: 华为云国内账号香港区域项目ID
gzprojectId: 华为云国内账号广州区域项目ID
```

## 输出格式
```
{"uuid":"63c4f703b33c2a0d3feb7b4ffc3d134f","cluster_name":"ubuntu","namespace":"common","type":"Deployment","name":"fuzz","container_name":"fuzz","liveness_probe":false,"readiness_probe":false,"startup_probe":false,"image":"swr.cn-south-1.myhuaweicloud.com/dexintec-bigdata/fuzz:v067490e","image_status":"存在"}
```


