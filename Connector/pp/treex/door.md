# 服务树外部连接器

## 导出服务树信息给第三方系统

例： 账单系统

```
./node # 导出服务树中的绑定关系，只包含主机
./dump # 导出cmdb中所有数据, 同时包含主机的部分，根据使用情况决定主机部分使用cmdb的还是./node
 
```
## 把使用的服务树导入到c3内部

切换服务树为使用c3服务树时使用

```
./todb | c3mc-base-savebind
```

## 服务树结构导入C3内部

```
c3mc-base-treemap | c3mc-base-savetree

```
