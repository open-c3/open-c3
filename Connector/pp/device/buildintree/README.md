# 服务树自动绑定/内置服务树

## v1 根据资源类型绑定服务树
```
cat /data/open-c3-data/buildintree/v1.yml 
database:
  huawei-rds: open-c3.database.mysql.huawei-rds
```

## v2 根据资源字段匹配进行服务树绑定

```
cat /data/open-c3-data/buildintree/v2.yml 
database:
  huawei-rds:
   - tree: open-c3.database.mysql.huawei-rds1
     match:
      - [ 'account', '/./' ]
      - [ 'private_ips.0', '/10.213.1/' ]

   - tree: open-c3.database.mysql.huawei-rds2
     match:
      - [ 'account', '/./', '/./' ]
      - [ 'private_ips.0', '^10' ]

   - tree: x
     match:
      - [ 'account', '/./' ]
      - [ 'private_ips.0', '/10/' ]
   - tree: open-c3.database.mysql.huawei-rds4

注:
   上面例子中一个资源类型下配置的是一个数组，会从上到下匹配. 匹配成功后后面的不会在匹配。
   match中是数组，是“与”的关系，需要同时满足。
   单个match中的元素也是数组，是”或“的关系。


   匹配规则三种写法:
       1. 正则： 写法 /xxx/, 在斜杠中间的部分是正则。 比如可以写 '/^1\.1\.1/' 或者 /\d+/
       2. 匹配开头: 写法 ^xxx , 以^开头的字符串表示匹配开头， 如 ^abc.d 表示匹配 abc.d开头的字符串。
       3. 相等， 除了上面两种情况就是完全匹配  如 [ 'account', 'foo', 'bar' ] 是比较 account 是不是等于foo或者bar。

   服务树为“x”的时候表示忽略。比如 如果想某个网段的资源不想自动绑定服务树，可以让它匹配上名为 “x” 的服务树。
```
