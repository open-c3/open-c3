###数据库发布

use connector;

create table `openc3_connector_sysupdate`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`uuid` VARCHAR(100) comment 'uuid',
`stat` VARCHAR(100) comment 'stat',
`time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment 'time',
UNIQUE KEY `uniq_uuid` (`uuid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='sysupdate';

### 数据库回滚

use connector;
drop table openc3_connector_sysupdate;
