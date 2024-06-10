# CMDB/费用计算

## 使用方式
```
1. 把公有云的账号下载到如下路径

  /data/open-c3-data/c3mc-device-fee/年-月/文件名字.csv

  例:
  /data/open-c3-data/c3mc-device-fee/2024-05/price_bill_detail_xxx.csv

  注: 文件名不重要，随便一个名字即可。可以把多个云的账单详情下载到下面

2. 修改csv文件字段

  把上述文件的列名进行修改，csv文件可以有很多列，当前工具只识别三列，请把列名进行对应调整，分别为
    NAME: 资源名称
    UUID: 资源唯一编号
    Price: 该记录关联的费用

3.  通过命令查看服务树资源费用
  c3mc-device-fee --tree 服务树 --date 月份
  例: c3mc-device-fee --tree open-c3.ops --date 2024-04

  注: 当前服务树匹配是根据字符串匹配的方式，包含对应字符串即被包含进来，
      如例子中的open-c3.ops，只要资源在任何服务树中的字符串中包含open-c3.ops字符串即被包含进来。
```
