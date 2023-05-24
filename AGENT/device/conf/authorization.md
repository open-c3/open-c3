# 公有云/权限说明
---

## IP白名单
某些云的权限配置需要同时添加访问IP白名单，请添加c3的出口IP白名单, 否则某些功能无法正常运行。

---
## 权限点说明

### 腾讯云

请创建一个自定义策略，在该策略中分配如下权限，可以直接复制如下配置创建自定义策略。
```json
{
    "version": "2.0",
    "statement":
    [
        {
            "effect": "allow",
            "action":
            [
                "cam:ListMaskedSubAccounts",
                "cam:ListAttachedUserAllPolicies",
                "cam:GetPolicy",
                "cam:CreatePolicyVersion",
                "cam:DeletePolicyVersion",
                "finance:*",
                "cvm:StopInstances",
                "cvm:DetachCbsStorages",
                "cvm:TerminateCbsStorages",
                "cvm:TerminateInstances",
                "cvm:RunInstances",
                "cvm:DescribeSecurityGroups",
                "cvm:DescribeInstances",
                "cvm:DescribeCbsStorages",
                "cvm:DescribeImages",
                "dcdb:DescribeProjects",
                "cdb:DescribeDBInstances",
                "cdb:ModifyInstanceTag",
                "cdb:CreateDBInstanceHour",
                "cdb:CreateDBInstance",
                "cdb:DescribeParamTemplates",
                "cdb:IsolateDBInstance",
                "cdb:OfflineIsolatedInstances",
                "cdb:OpenWanService",
                "ckafka:DescribeInstances",
                "clb:DescribeLoadBalancers",
                "clb:CreateLoadBalancer",
                "clb:CreateListener",
                "clb:CreateRule",
                "clb:RegisterTargets",
                "clb:DeleteLoadBalancer",
                "redis:DescribeInstances",
                "vpc:DescribeVpcEx",
                "vpc:DescribeSubnetEx",
                "cos:GetService",
                "mongodb:DescribeDBInstances",
                "mongodb:DescribeDBInstanceNodeProperty",
                "sqlserver:DescribeDBInstances",
                "tag:TagResources",
                "tag:UnTagResources",
                "cynosdb:DescribeInstances",
                "monitor:*"
            ],
            "resource":
            [
                "*"
            ]
        }
    ]
}
```

在上面的策略中，
```json
[
  "cam:ListMaskedSubAccounts",
  "cam:ListAttachedUserAllPolicies",
  "cam:GetPolicy",
  "cam:DeletePolicyVersion",
]
```
这四项是不需要的，但是没这四项会导致在腾讯云控制台无法查看、编辑、更新策略。为了方便管理，默认加上了。

---

### aws

```json
{
    "Version": "2012-10-17",
    "Statement":
    [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action":
            [
                "ec2:DescribeInstances",
                "ec2:DescribeVolumes",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeAddresses",
                "ec2:DeleteTags",
                "ec2:DescribeInstanceTypeOfferings",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeSubnets",
                "ec2:RunInstances",
                "ec2:DescribeRegions",
                "ec2:AssociateAddress",
                "ec2:CreateTags",
                "ec2:DescribeVpcs",
                "ec2:DescribeImages",
                "ec2:DescribeSecurityGroups",
                "ec2:StopInstances",
                "ec2:StartInstances",
                "ec2:AllocateAddress",
                "ec2:DisassociateAddress",
                "ec2:ReleaseAddress",
                "ec2:TerminateInstances",
                "ec2:ModifyInstanceAttribute",
                "iam:CreateRole",
                "iam:AddRoleToInstanceProfile",
                "iam:DetachUserPolicy",
                "iam:ListPolicies",
                "iam:GetPolicy",
                "iam:ListGroupsForUser",
                "iam:CreateInstanceProfile",
                "iam:PassRole",
                "iam:ListAttachedUserPolicies",
                "iam:CreatePolicyVersion",
                "iam:ListRoles",
                "iam:ListUsers",
                "iam:ListUserPolicies",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions",
                "iam:DeletePolicyVersion",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:DescribeTags",
                "lightsail:GetInstances",
                "lightsail:GetLoadBalancers",
                "lightsail:GetRelationalDatabases",
                "kafka:ListClustersV2",
                "rds:RemoveTagsFromResource",
                "rds:DescribeDBInstances",
                "rds:AddTagsToResource",
                "dynamodb:ListTables",
                "dynamodb:TagResource",
                "dynamodb:UntagResource",
                "dynamodb:DescribeTable",
                "dynamodb:ListTagsOfResource",
                "pricing:GetProducts",
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation",
                "s3:GetBucketTagging",
                "elasticache:RemoveTagsFromResource",
                "elasticache:AddTagsToResource",
                "elasticache:DescribeCacheClusters",
                "route53:ListHostedZones",
                "route53:ListTagsForResources",
                "route53:ListResourceRecordSets",
                "sts:DecodeAuthorizationMessage"
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
  "GaussDB NoSQL FullAccess",
  "OBS FullAccess",
  "DMS FullAccess",
  "ELB FullAccess"
]
```
**注意**: 截止2023年2月21日，华为云 北京一(cn-north-1) 和 上海二(cn-east-2) 的资源已经卖完，目前属于私有区域。但是因为华为云接口问题，获取到的项目列表里仍旧包含这俩区域，导致c3从这俩区域获取资源出现403错误，**因此配置用户组权限时，在 "选择授权范围方案" 选项下，点击"指定区域项目资源"，然后选择你要授权的项目列表，这样可以排除上述的那俩特殊区域**。

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
  "compute.regions.list",
  "redis.instances.list",
]
```
