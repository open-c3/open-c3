# 服务树/批量修改服务树名称

```
#Open-C3中服务树的信息存储是一个扁平的结构，目前没有在页面添加修改非叶子节点名称的界面。
#如果有修改需求，可以使用下面命令进行修改。

#例子:
c3mc-base-db-get -t openc3_connector_tree id name |grep demo.treetest|sed s/demo/dev/ | c3mc-base-tree-load

```
