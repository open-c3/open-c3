# 系统迁移/同步服务树绑定关系

## 用法

### sync.sh

在本目录添加如下sync.sh脚本，从老系统中下载绑定数据，同时加载到系统中

```
#!/bin/bash

set -e

cd /data/Software/mydan/Connector/pp/treesync

wget http://old.sys.domain.com/api/scripts/alias.yml  -O alias.yml.temp.$$
mv alias.yml.temp.$$ alias.yml

wget http://old.sys.domain.com/api/scripts/treebind.txt -O treebind.txt.temp.$$
mv treebind.txt.temp.$$ treebind.txt

./dump| c3mc-base-savebind
```

### crontask

定时执行同步任务，可以把任务添加到/data/open-c3/Connector/openc3.task.crontab中

```
*/5 * * * * root flock -n /tmp/treesync.lock /data/Software/mydan/Connector/pp/treesync/sync.sh > /tmp/treesync.log 2>&1
```

## 数据样例

### alias

资源id别名,dump脚本生成的数据会把uuid进行更换后在输出。所以导入数据库的是右边的id。

```
#head alias.yml 
---
000071ab50ceb19f: i-0bc0226045d3e1653
0001e9e95c5e8abb: i-011173d9af83bf779
000204c7ae1a9d87: i-029e67740a4f6f170
0002119c-d4f3-411a-9de5-8c1ec58422a2: 0002119c-d4f3-411a-9de5-8c1ec58422a2
0002244ed9e3fc4d: aa9fc7c95f3e311e9870206b90fe3dbb
0002a068c19abc02: i-0c4568d16e30ac3cd
00031420b7418086: i-07903540c980a355f
00035c7d33bc71d1: 00035c7d33bc71d1
00036fd3492e1408: rm-d9j3mn007gxi9vbz8
```

### treebind

服务树绑定关系，数据为两列，第一列是资源id，第二列是服务树id。资源如果绑定了多个服务树，可以看到资源有多行记录。

```
#head treebind.txt 
3e647efbd1b1f193 0
817f3a497823f8b0 0
08cf9e30247a2169 0
ba378dde5f6294df 0
b9a3e9ead8d93157 0
732e93d28106e70e 0
3d3658c8512d21f5 0
45c263ba32657155 0
67ca292b6250f221 0
73a04a653ddd1f60 0

```

### oldtree

如果系统中已经存在了部分的绑定关系。同步过来后会进行覆盖。为了避免覆盖或者自定义部分的服务树。可以把已经存在的服务树或者希望额外追加的服务树，

可以把绑定关系放到这个文件中，多个服务树用逗号分隔。

```
#head oldtree.yml 
cdb-l13o80r2: test.openc3.c3_mon_database.mysql.qcloud_cdb,tree.test2
cdb-poqbzhnn: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-ji50045i: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-jpbhtn62: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-j51nzm3y: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-gn9pyix2: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-kkl07z3e: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-64mihr1o: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-6skbipb8: test.openc3.c3_mon_database.mysql.qcloud_cdb
cdb-pz7giveq: test.openc3.c3_mon_database.mysql.qcloud_cdb
```
