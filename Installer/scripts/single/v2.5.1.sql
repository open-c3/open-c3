###数据库发布

use agent;

create table `openc3_monitor_config_collector`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',
`type` VARCHAR(100) comment '类型',
`subtype` VARCHAR(100) comment '子类型',
`content1` VARCHAR(300) comment '内容',
`content2` VARCHAR(300) comment '内容',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='monitorconfigcollector';

create table `openc3_monitor_config_rule`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',
`alert` VARCHAR(100) comment 'alert',
`expr` VARCHAR(3000) comment 'expr',
`for` VARCHAR(100) comment 'for',
`severity` VARCHAR(100) comment 'severity',
`summary` VARCHAR(1000) comment 'summary',
`description` VARCHAR(1000) comment 'description',
`value` VARCHAR(100) comment 'value',
`model` VARCHAR(100) comment 'model',#simple,custom
`metrics` VARCHAR(100) comment 'metrics',
`method` VARCHAR(20) comment 'method',#> < >= <=
`threshold` VARCHAR(100) comment 'threshold',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='monitorconfigrule';

create table `openc3_monitor_config_user`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',
`user` VARCHAR(100) comment 'user',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='monitorconfiguser';


#alter table openc3_monitor_config_rule modify column `summary` varchar(1000) DEFAULT NULL COMMENT 'summary';

### 数据库回滚

use agent;

drop table openc3_monitor_config_collector;
drop table openc3_monitor_config_rule;
drop table openc3_monitor_config_user;
