###数据库发布

use connector;

create table `openc3_connector_userdepartment`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`user` VARCHAR(100) comment 'user',
`department` VARCHAR(100) comment 'department',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment 'time',
`edit_user` VARCHAR(100) comment 'edit_user',
UNIQUE KEY `uniq_user` (`user`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='userdepartment';

### 数据库回滚

use connector;

drop table openc3_connector_userdepartment;
