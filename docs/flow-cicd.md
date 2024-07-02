# 发布流程对接到第三方系统

## 通过分支发布
```
获取流水线的branch列表
http://openc3.xxx.com/api/ci/v2/c3mc/cibranch/$flowid

例: 
http://openc3.xxx.com/api/ci/v2/c3mc/cibranch/362
其中362是流水线编号

指定流水线和分支名称提交一个发布请求，可以用get或者post请求，最好用post请求，get是用于调试的，后面可能会关闭。这个请求会返回一个发布的版本号，用这个版本号通过查询API请求是否发布到了这个版本。
http://openc3.xxx.com/api/ci/v2/c3mc/cibranch/$flowid/$branch

例:
http://openc3.xxx.com/api/ci/v2/c3mc/cibranch/362/v2.6.0
其中362是流水线编号, v2.6.0是要发布的分支

```

## 通过tags发布
```
获取流水线的tags的列表
http://openc3.xxx.com/api/ci/v2/c3mc/citags/$flowid

例: 
http://openc3.xxx.com/api/ci/v2/c3mc/citags/362
其中362是流水线编号

指定流水线和分支名称提交一个发布请求，可以用get或者post请求，最好用post请求，get是用于调试的，后面可能会关闭。这个请求会返回一个发布的版本号，用这个版本号通过查询API请求是否发布到了这个版本。
http://openc3.xxx.com/api/ci/v2/c3mc/citags/$flow/$tags

例:
http://openc3.xxx.com/api/ci/v2/c3mc/citags/362/release-v2.6.0
其中362是流水线编号, release-v2.6.0是要发布的tags

```

## 查询发布状态
```
通过上一个接口返回的版本号，和这个接口返回的版本号进行对比，如果版本一致，说明发布成功了。这个接口显示的是当前流水线最后发布成功的版本。
http://openc3.xxx.com/api/jobx/flowline_version/$flowid

或者直接指定版本，查询该版本是否发送成功
http://openc3.xxx.com/api/jobx/task/flowline/status/$flowid/$version

例:
http://openc3.xxx.com/api/jobx/task/flowline/status/362/release-v2.6.0-20240329153433

```
