### 数据库发布

use agent;

create table `openc3_monitor_config_mailmon`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`name` VARCHAR(300) comment '名称',
`description` VARCHAR(1000) comment '描述',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `name` (`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='邮件监控';

create table `openc3_monitor_history_mailmon`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`account` VARCHAR(300) comment '账号',
`severity` VARCHAR(300) comment '级别',
`subject` VARCHAR(500) comment '标题',
`content` VARCHAR(1000) comment '内容',
`date` VARCHAR(300) comment '日期',
`from` VARCHAR(300) comment '来源',
`create_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='邮件监控历史';

### 数据库回滚

use agent;

drop table openc3_monitor_config_mailmon;
drop table openc3_monitor_history_mailmon;
