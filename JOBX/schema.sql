create database jobx;
use jobx;

create table `group`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',

`name` VARCHAR(100) comment '分组名',
`note` VARCHAR(200) comment '备注',

`group_type` VARCHAR(100) comment '分组类型',
`group_uuid` VARCHAR(100) comment '分组编号',

`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '最后编辑时间',
UNIQUE KEY `uniq_pn` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='group';

create table `group_type_list`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`uuid` VARCHAR(20) comment '唯一编号',

`node` VARCHAR(2000) comment '节点列表,用逗号分隔节点,用分号分隔分组',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='列表分组';


create table `group_type_percent`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`uuid` VARCHAR(20) comment '唯一编号',

`percent` VARCHAR(2000) comment '比例',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='百分比分组';


create table `task`(
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

create table `subtask`(
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


create table `keepalive`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`slave` VARCHAR(40) comment 'slave',
`time` int(16) unsigned comment 'time',
UNIQUE KEY `uniq_slave` (`slave`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='slave心跳';

create table `monitor`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`time` VARCHAR(40) comment '时间',
`time_s` VARCHAR(40) comment '时间秒数',
`stat` VARCHAR(40) comment '状态',
`host` VARCHAR(40) comment '机器',
`type` VARCHAR(40) comment '类型',
`key` VARCHAR(40) comment '监控名',
`val` VARCHAR(40) comment '数值',
UNIQUE KEY `uniq_host_type_key` ( `host`,`type`,`key`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='监控';

