# 工单数据迁移

## dump 旧的数据

mysqldump  -h $host -uroot -p$password  --no-create-info --databases tt > tt.sql

## 更新sql语句,添加表前缀

```
sed -i 's/^USE `.*`;/USE `connector`;/'  tt.sql
sed -i '/^CREATE DATABASE/d'             tt.sql

sed -i 's/`base_category`/`openc3_tt_base_category`/g'                             tt.sql 
sed -i 's/`base_email_templates`/`openc3_tt_base_email_templates`/g'               tt.sql 
sed -i 's/`base_group`/`openc3_tt_base_group`/g'                                   tt.sql 
sed -i 's/`base_group_user`/`openc3_tt_base_group_user`/g'                         tt.sql 
sed -i 's/`base_impact`/`openc3_tt_base_impact`/g'                                 tt.sql 
sed -i 's/`base_item`/`openc3_tt_base_item`/g'                                     tt.sql 
sed -i 's/`base_item_group_map`/`openc3_tt_base_item_group_map`/g'                 tt.sql 
sed -i 's/`base_type`/`openc3_tt_base_type`/g'                                     tt.sql 
sed -i 's/`common_lang`/`openc3_tt_common_lang`/g'                                 tt.sql 
sed -i 's/`common_reply_log`/`openc3_tt_common_reply_log`/g'                       tt.sql 
sed -i 's/`common_sys_log`/`openc3_tt_common_sys_log`/g'                           tt.sql 
sed -i 's/`common_work_log`/`openc3_tt_common_work_log`/g'                         tt.sql 
sed -i 's/`ticket`/`openc3_tt_ticket`/g'                                           tt.sql 
sed -i 's/`ticket_attachment`/`openc3_tt_ticket_attachment`/g'                     tt.sql 

cp tt.sql /data/open-c3/Connector/tt/init/init.sql

```

## 初始化数据库

到容器中执行: cd /data/Software/mydan/Connector/tt/init && ./dbinit.sh force
