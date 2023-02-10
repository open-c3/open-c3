# 云账号权限说明
---

## IP白名单
某些云的权限配置需要同时添加访问IP白名单，请添加c3的出口IP白名单, 否则某些功能无法正常运行。

---
## 权限点说明

### 腾讯云

```json
{
    "version": "2.0",
    "statement": [
        {
            "effect": "allow",
            "action": [
                "cdb:DescribeDBInstances",
                "ckafka:DescribeInstances",
                "clb:DescribeLoadBalancers",
                "cvm:DescribeInstances",
                "redis:DescribeInstances",
                "vpc:DescribeVpcEx",
                "cos:GetService",
                "cvm:DescribeCbsStorages",
                "vpc:DescribeSubnetEx",
                "mongodb:DescribeDBInstances",
                "sqlserver:DescribeDBInstances",
                "mongodb:DescribeDBInstanceNodeProperty",
                "tag:TagResources",
                "cdb:ModifyInstanceTag",
                "tag:UnTagResources"
            ],
            "resource": [
                "*"
            ]
        }
    ]
}
```

---

### aws

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "rds:AddTagsToResource",
        "ec2:DescribeInstances",
        "elasticache:RemoveTagsFromResource",
        "dynamodb:UntagResource",
        "ec2:DeleteTags",
        "dynamodb:ListTables",
        "elasticloadbalancing:DescribeTags",
        "ec2:CreateTags",
        "elasticache:AddTagsToResource",
        "pricing:GetProducts",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:RemoveTags",
        "dynamodb:TagResource",
        "s3:ListAllMyBuckets",
        "ec2:DescribeVpcs",
        "elasticloadbalancing:AddTags",
        "ec2:DescribeVolumes",
        "rds:DescribeDBInstances",
        "elasticache:DescribeCacheClusters",
        "rds:RemoveTagsFromResource",
        "kafka:ListClustersV2"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 华为云

在华为云创建自定义策略，里面可以包含某个资源的单个权限点。如果是多个资源的情况，需要创建多个自定义策略，这样导致创建最小权限比较繁琐。可以直接在资源类型上分配只读权限。

下面权限中，需要完整访问权限是因为某些资源标签修改需要写权限。
```json
[
  "ECS FullAccess",
  "DCS FullAccess",
  "DDS FullAccess",
  "RDS FullAccess",
  "EVS FullAccess",
  "GaussDB NoSQL ReadOnlyAccess",
  "OBS ReadOnlyAccess",
  "ELB ReadOnlyAccess"
]
```

---

### 金山云

```json
[
  "EPCReadOnlyAccess",
  "VPCReadOnlyAccess",
  "TagFullAccess",
  "KECReadOnlyAccess",
  "SLBReadOnlyAccess",
  "EBSReadOnlyAccess",
  "KRDSReadAccess",
  "KCSReadAccess",
  "KS3ReadOnlyAccess"
]
```

---

### 阿里云

下面权限中，需要完整访问权限是因为某些资源标签修改需要写权限。
```json
[
  "AliyunVPCReadOnlyAccess",
  "AliyunECSFullAccess",
  "AliyunRDSFullAccess",
  "AliyunKvstoreFullAccess",
  "AliyunOSSFullAccess",
  "AliyunSLBFullAccess"
]
```

---

### 谷歌云

请在谷歌云控制台启用如下服务:

```json
["Cloud SQL Admin API"]
```

需要的权限点如下：

```json
[
  "cloudsql.instances.get",
  "cloudsql.instances.list",
  "cloudsql.instances.update",
  "compute.disks.get",
  "compute.disks.list",
  "compute.disks.setLabels",
  "compute.instances.get",
  "compute.instances.list",
  "compute.instances.setLabels",
  "compute.images.get",
  "redis.instances.list",
]
```
