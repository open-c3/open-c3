# BPM/插件说明/approval

## 例子

如下是一个常规的审批插件配置

```
---
name: 运维审批
option:
  - describe: 运维审批人
    name: approver
    type: selectx
    value: ""
    command: "c3mc-bpm-optionx-opapprover"

template_argv:
  approver: ${approver}
  title:    "BPM/${_bpmuuid_}/资源申请/腾讯云/CVM"
  content:  "\n申请人:${_user_}\nBPM单号:${_bpmuuid_}\n申请理由:${x.note}"
```

其中template_argv下的approver是审批人

## 字段描述
```
template_argv字段描述:

  approver: 审批人
  title:    审批的标题
  content:  审批的内容

  everyone: 1 # 可选，为1时说明每个人都需要审批，没有配置或者为0时，说明只要审批列表中的一个人进行审批即可。
  relaxed:  1 # 可选，如果发起人和审批人是同一个人时，跳过这个人的审批。

  submitter: sys@app # 可选，默认不写的情况下发起人是sys@app
  timeout:   86400   # 可选，默认是86400秒

  record: 1 # 可选，默认为0， 当为1是，说明该审批人是当前流程的处理人
```

## 扩展
为了满足不同的需求，对approver进行了扩展，扩展函数如下:

### leader 领导审批

如下是资源审批时，提交人领导审批的例子

```
---
name: '提交人的领导审批'
option:
  - describe: 申请理由
    name: note
    type: text
    value: ""

template_argv:
  approver: "leader(${_user_})"
  title:    "BPM/${_bpmuuid_}/资源申请/腾讯云/CVM"
  content:  "\n申请人:${_user_}\nBPM单号:${_bpmuuid_}\n申请理由:${x.note}"
```

### sudoer & ipowner & or

sudoer人审批
资源的ip查找owner，该owner审批
or 关键字，会按照顺序查找，如果找不到前面的审批人就往下找，例子中找不到sudo审批人，就找资源owner审批。

```
---
name: 领导审批或者资源owner审批
option:
  - describe: 申请理由
    name: note
    type: text
    value: 

template_argv:
  approver: "sudoer(${x.auth_type},${_user_}) or ipowner(${x.ip_list})"
  title:    "BPM/${_bpmuuid_}/申请服务器权限"
  content:  "\n申请人:${_user_}\n权限类型:${x.auth_type__alias}\n服务器ip列表:${x.ip_list}\nBPM单号:${_bpmuuid_}\n申请理由:${x.note}"
```

注：sudo审批人
```
在某些企业中，申请资源sudo权限有一个特殊的映射关系，如果存在下面两个文件，说明有sudo审批人的映射关系.
其中sudo0是普通的机器权限，sudo1是申请机器的sudo权限。

[root@bogon approval]# cat /data/open-c3-data/bpm/sudoer0.conf 
open-c3: user001
[root@bogon approval]# cat /data/open-c3-data/bpm/sudoer1.conf 
open-c3: user002
```

### k8sowner

k8s集群的owner审批。

```
---
name: kubernetes集群owner审批
option:
  - describe: 申请理由
    name: note
    type: text
    value: 

template_argv:
  approver: "k8sowner(${x.cluster})"
  title:    "BPM/${_bpmuuid_}/申请在K8S集群中创建应用"
  content:  "\n申请人:${_user_}\n集群ID:${x.cluster}\n集群名称:${x.cluster__alias}\n应用模版:${x.template}\nBPM单号:${_bpmuuid_}\n申请理由:${x.note}"
```
