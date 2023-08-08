# 第三方接口/审批

## 发起审批
```

请求:

user_id: 发起人
special_approver: 审批人
title: 审批标题
apply_note: 审批内容

curl --location --request POST 'http://YOUR_OPENC3_IP/api/job/to3part/v1/approval' \
--header 'appkey: your_appkey' \
--header 'appname: your_appname' \
--header 'Content-Type: application/json' \
--data-raw '{ 
  "user_id": "user1@openc3.org",
  "route_user_id": "",
  "special_approver": "user2@openc3.org",
  "route_node": "0",
  "apply_note": "审批的内容",
  "title": "审批的标题",
  "participant": ""
}'

返回:

其中的djbh字段的内容就是该审批单子的唯一编号，后面用这个这个编号查询审批的状态。

{
   "mesg" : "ok",
   "stat" : true,
   "code" : 0,
   "data" : {
      "djbh" : "9XFHBJySvnhh",
      "msg" : "ok"
   }
}


```

## 查询审批状态

```

查询:

djbh: 要查询的审批单的唯一编号。

curl --location --request GET 'http://YOUR_OPENC3_IP/api/job/to3part/v1/approval?djbh=9XFHBJySvnhh' --header 'appkey: your_appkey' --header 'appname: your_appname'

返回:
actionname有三种状态：待办、同意、不同意

{
   "stat" : true,
   "code" : 0,
   "msg" : "ok",
   "data" : {
      "isend" : 0,
      "data" : [
         {
            "actionname" : "待办"
         }
      ]
   }
}

```
