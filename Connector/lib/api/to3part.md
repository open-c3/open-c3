# 第三方接口/用户

## 获取用户部门信息

```

请求:

email: 要查询的用户的名（邮件地址）

curl --location --request GET 'http://YOUR_OPENC3_IP/api/connector/to3part/v1/user/department?email=user@openc3.org' --header 'appkey: your_appkey' --header 'appname: your_appname'

返回:
{
   "msg" : "ok",
   "data" : {
      "sybDeptName" : "产品线名称",
      "oneDeptName" : "一级部门",
      "twoDeptName" : "二级部门",
      "sybLeaderId" : "产品线领导",
      "oneLeaderId" : "一级部门领导",
      "twoLeaderId" : "二级部门领导",
      "accountName" : "用户名",
      "accountId" : "用户账号",
      "mobile" : "手机号"
   },
   "code" : 0,
   "stat" : true
}

```

## 获取用户信息

token: 用户的cookie

```
请求:
curl --location --request GET 'http://YOUR_OPENC3_IP/api/connector/to3part/v1/user/userinfo'   -H 'token: PfH42PD5PDGFAaHa7eunF6qIf9HsbgXvCQ03JlzcA52MFUqX5twcQGs579vmZcYX'

返回:
{
   "admin" : "1",
   "showconnector" : "1",
   "company" : "ccc123",
   "name" : "OPEN-C3",
   "email" : "open-c3"
}
```
