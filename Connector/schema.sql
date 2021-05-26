create database connector;
use connector;

create table `openc3_connector_group`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',

`name` VARCHAR(100) comment '分组名',
`note` VARCHAR(200) comment '备注',

`group_type` VARCHAR(100) comment '分组类型',
`group_uuid` VARCHAR(100) comment '分组编号',

`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '最后编辑时间',
UNIQUE KEY `uniq_pn` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='group';

create table `openc3_connector_group_type_list`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`uuid` VARCHAR(20) comment '唯一编号',

`node` VARCHAR(2000) comment '节点列表,用逗号分隔节点,用分号分隔分组',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='列表分组';


create table `openc3_connector_group_type_percent`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`uuid` VARCHAR(20) comment '唯一编号',

`percent` VARCHAR(2000) comment '比例',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='百分比分组';


create table `openc3_connector_task`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',

`uuid` VARCHAR(20) BINARY comment '唯一编号',
`name` VARCHAR(100) comment '任务名称',
`group` VARCHAR(100) comment '机器分组',
`user` VARCHAR(100) comment '启动人',
`slave` VARCHAR(40) comment 'slave',
`status` VARCHAR(20) comment '状态',
`starttimems` VARCHAR(20) comment '开始时间包涵毫秒信息',
`finishtimems` VARCHAR(20) comment '结束时间包涵毫秒信息',
`starttime` VARCHAR(20) comment '开始时间',
`finishtime` VARCHAR(20) comment '结束时间',
`calltype` VARCHAR(100) comment '触发类型',
`pid` int(16) unsigned comment 'pid',
`runtime` VARCHAR(100) comment '任务总耗时',
`variable` VARCHAR(1000) comment '私有变量',
`reason` VARCHAR(100) comment '成功/失败的原因',
UNIQUE KEY `uniq_taskid` (`uuid`),
INDEX index_name(`status`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='任务列表';

create table `openc3_connector_subtask`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',

`parent_uuid` VARCHAR(20) comment '父任务uuid',
`uuid` VARCHAR(20) comment 'uuid',

`nodelist` VARCHAR(2000) comment '机器列表',
`nodecount` VARCHAR(20) comment '机器数量',
`starttime` VARCHAR(20) comment '开始时间',
`finishtime` VARCHAR(20) comment '结束时间',
`runtime` VARCHAR(100) comment '任务总耗时',
`status` VARCHAR(20) comment '状态', #runnigs,fail,success,decision,ignore,next
`confirm` VARCHAR(50) comment '确认', #为WaitConfirm时表示需要确认,确认后保存确认人信息

UNIQUE KEY `uniq_uuid` ( `uuid`),
INDEX index_name(`parent_uuid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='子任务列表';


create table `openc3_connector_keepalive`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`slave` VARCHAR(40) comment 'slave',
`time` int(16) unsigned comment 'time',
UNIQUE KEY `uniq_slave` (`slave`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='slave心跳';

create table `openc3_connector_log`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',

`projectid` int(16) unsigned comment '项目id',

`user` VARCHAR(100) comment '操作人',
`info` VARCHAR(200) comment '日志信息',

`create_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'

)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='log';


create table `openc3_connector_userinfo`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`name` VARCHAR(100) comment 'name',
`pass` VARCHAR(200) comment 'pass',
`sid` VARCHAR(200) comment 'sid',
`expire` VARCHAR(200) comment 'expire',
UNIQUE KEY `uniq_name` (`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='userinfo';

create table `openc3_connector_userauth`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`name` VARCHAR(100) comment 'name',
`level` VARCHAR(200) comment 'level',
UNIQUE KEY `uniq_name` (`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='userauth';


create table `openc3_connector_usermesg`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`user` VARCHAR(100) comment 'name',
`time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment 'time',
`mesg` VARCHAR(1000) comment 'mesg'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='usermesg';


create table `openc3_connector_usermail`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`user` VARCHAR(100) comment 'name',
`time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment 'time',
`title` VARCHAR(200) comment 'title',
`content` VARCHAR(2000) comment 'mesg'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='usermail';

create table `openc3_connector_tree` (
`id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
`name` varchar(50) NOT NULL UNIQUE COMMENT '节点名',
`len` int(1) NOT NULL COMMENT '节点的长度',
`update_time` DATETIME NOT NULL COMMENT '更新时间',
PRIMARY KEY (`id`),
KEY `index_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='系统信息表' AUTO_INCREMENT=1 ;


create table `openc3_connector_nodelist`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment 'projectid',
`name` VARCHAR(100) comment '机器名',
`inip` VARCHAR(50) comment '内网ip',
`exip` VARCHAR(50) comment '外网ip',
`type` VARCHAR(50) comment '类型',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted

UNIQUE KEY `uniq_projectname` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='机器列表';

create table `openc3_connector_auditlog`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment 'time',
`user` VARCHAR(100) comment 'name',
`title` VARCHAR(200) comment 'title',
`content` VARCHAR(1000) comment 'mesg'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='auditlog';

create table `openc3_connector_useraddr`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`user` VARCHAR(100) comment 'user',
`email` VARCHAR(100) comment 'email',
`phone` VARCHAR(100) comment 'phone',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment 'time',
`edit_user` VARCHAR(100) comment 'edit_user',
UNIQUE KEY `uniq_user` (`user`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='useraddr';

