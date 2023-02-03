# 监控采集器/云监控/华为云

配置例子:
```
global:
  prefix: "huaweicloud"
  scrape_batch_size: 300

auth:
  auth_url: "https://iam.cn-north-4.myhuaweicloud.com/v3"
  project_name: "cn-north-4"
  access_key: "xxx"
  secret_key: "xxx"
  region: "cn-north-4"

metric: simple # simple or full
services: SYS.RDS,SYS,ECS
```
