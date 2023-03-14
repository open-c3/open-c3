# BPM/插件说明

## 审批插件

bpm的审批插件，支持“or”方式。

“or”方式会从做到右查找审批人，直到找到至少一个审批人为止。

同时做了如下扩展：

leader(foo,bar) 格式，查找对应的人的领导，如果有如下配置文件，会在里面查找领导。
```
cat /data/open-c3-data/bpm/leader.conf
open-c3: open-c2
open-c5: open-c4

```

ipowner(${x.ip_list})格式，会找到所有资源的资源owner。

```
---
name: 领导审批或者资源owner审批
option:
#  - describe: 运维审批人
#    name: opapprover
#    type: selectx
#    value: ""
#    command: "c3mc-bpm-optionx-opapprover"

  - describe: 申请理由
    name: note
    type: text
    value: 

template_argv:
  approver: "leader(${_user_}) or ipowner(${x.ip_list})"
  title:    "BPM/${_bpmuuid_}/申请服务器权限"
  content:  "\n申请人:${_user_}\n登录账号:${x.account}\n服务器ip列表:${x.ip_list}\nBPM单号:${_bpmuuid_}\n申请理由:${x.note}"
```
