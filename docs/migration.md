===================================================
# 服务树导入

## 清空
```
use connector;
delete from  openc3_connector_tree;
```
## 导入
```
c3mc-base-treemap | c3mc-base-savetree
```
## 检查
```
select * from openc3_connector_tree;
```
===================================================
# 主机绑定关系导入

## 检查
```
use agent;
select * from openc3_device_bindtree;
```
## 导入
```
cd /data/Software/mydan/Connector/pp/treex

./todb | c3mc-base-savebind
```
## 检查一下数据

===================================================
# 切换

## 切换current

config.inix/current

登录和服务树权限服务树nodeinfo

## c3-restart

## 修正监控

修复监控看版抱错,提示异常，cookie变化引起的。

cookie 从sid修改成u之后，可能会异常，/data/open-c3/open-c3.sh start 修复
【注意：此处主容器可能会recreate,如果是使用高峰期，可以先手动修复】

# 系统参数中 ，摄取主机 开关打开

c3-restart
