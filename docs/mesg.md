# 消息出口规范

## 发邮件
```
curl -H "Content-Type: application/json"  -H 'appname: xxx' -H 'appkey: xxxxxx'   -X POST -d '{"user": "lijinfeng2011@gmail.com","title": "邮件标题", "content": "邮件内容" }' 'http://mesg.c3.xxx.org:8080/mail?encode=1'
```

## 发短信
```
curl -H "Content-Type: application/json"  -H 'appname: xxx' -H 'appkey: xxxxxx'   -X POST -d '{"user": "1331136xxxx","mesg": "短信内容" }' 'http://mesg.c3.xxx.org:8080/mesg'
```

## 打电话
```
curl -H "Content-Type: application/json"  -H 'appname: xxx' -H 'appkey: xxxxxx'   -X POST -d '{"user": "1331136xxxx","mesg": "您好，电话测试" }' http://mesg.c3.xxx.org:8080/call
```
