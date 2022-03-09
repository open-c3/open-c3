###数据库发布

use agent;

create table `openc3_monitor_config_group`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`name` VARCHAR(300) comment '名称',
`description` VARCHAR(1000) comment '描述',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `name` (`name`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='监控报警接收组';

create table `openc3_monitor_config_groupuser`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`groupid` int(16) unsigned comment '监控报警接收组id',
`user` VARCHAR(300) comment '用户',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `groupid_user` (`groupid`, `user`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='监控报警接收组成员';

### 数据库回滚

use agent;

drop table openc3_monitor_config_group;
drop table openc3_monitor_config_groupuser;
