# cloudwatch_exporter

https://github.com/prometheus/cloudwatch_exporter

# 配置例子
```
---
ak: 'ak'
sk: 'sk'

region: us-west-2
metrics:
 - aws_namespace: AWS/RDS
   aws_metric_name: DatabaseConnections
   aws_dimensions: [ DBInstanceIdentifier]
   aws_statistics: [Maximum]

 - aws_namespace: AWS/RDS
   aws_metric_name: CPUUtilization
   aws_dimensions: [ DBInstanceIdentifier]
   aws_statistics: [Maximum]

 - aws_namespace: AWS/RDS
   aws_metric_name: FreeStorageSpace
   aws_dimensions: [ DBInstanceIdentifier]
   aws_statistics: [Maximum]

 - aws_namespace: AWS/ELB
   aws_metric_name: RequestCount
   aws_dimensions: [AvailabilityZone, LoadBalancerName]
   aws_statistics: [Sum]

```
# 获取metrics列表
AWS_ACCESS_KEY_ID='ak' AWS_SECRET_ACCESS_KEY='sk' aws cloudwatch list-metrics
