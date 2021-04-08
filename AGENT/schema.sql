create database agent;
use agent;

create table `region`(
`id`            int(16) unsigned not null primary key auto_increment  comment 'id',
`projectid` int(16) unsigned comment '项目id',
`name` VARCHAR(100) comment '区域名称',

`create_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',

UNIQUE KEY `uniq_projectid_name` (`projectid`,`name`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='区域';

create table `project_region_relation`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',
`regionid` int(16) unsigned comment '区域id',

`create_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_projectid_regionid` (`projectid`,`regionid`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='使用的区域';


create table `proxy`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`regionid` int(16) unsigned comment '区域id',

`projectid` int(16) unsigned comment '项目id,仅用于和ip字段做唯一建',

`ip` VARCHAR(100) comment 'proxy的ip',
`status` VARCHAR(100) comment '状态',
`fail` int(16) unsigned default 0 comment '失败次数',
`reason` VARCHAR(100) comment '失败原因',
`version` VARCHAR(100) comment '版本',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_projectid_ip` (`projectid`,`ip`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='proxy';


create table `agent`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`relationid` int(16) unsigned comment '关系id',

`projectid` int(16) unsigned comment '项目id,仅用于和ip字段做唯一建',

`ip` VARCHAR(100) comment 'agent的ip',
`status` VARCHAR(100) comment '状态',
`fail` int(16) unsigned default 0 comment '失败次数',
`reason` VARCHAR(100) comment '失败原因',
`version` VARCHAR(100) comment '版本',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_projectid_ip` (`projectid`,`ip`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='agent';


create table `install`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',

`uuid` VARCHAR(100) comment '唯一编号',

`projectid` int(16) unsigned comment '项目id',
`regionid` VARCHAR(100) comment 'region的id',


`type` VARCHAR(100) comment '类型，agent或者proxy',
`ip` VARCHAR(100) comment 'ip列表，逗号或者空格分开',
`user` VARCHAR(100) comment '安装人',

`slave` VARCHAR(40) comment 'slave',
`pid` VARCHAR(20) comment 'pid',

`status` VARCHAR(20) comment '状态',
`success` VARCHAR(100) comment '成功机器数量',
`fail` VARCHAR(100) comment '失败机器数量',


`username` VARCHAR(20) comment '安装用户名',
`password` VARCHAR(50) comment '安装密码',

`starttimems` VARCHAR(20) comment '开始时间包涵毫秒信息',
`finishtimems` VARCHAR(20) comment '结束时间包涵毫秒信息',
`starttime` VARCHAR(20) comment '开始时间',
`finishtime` VARCHAR(20) comment '结束时间',
`runtime` VARCHAR(100) comment '任务总耗时',

UNIQUE KEY `uniq_uuid` (`uuid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='install';


create table `install_detail`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',

`uuid` VARCHAR(100) comment 'install的编号编号',

`type` VARCHAR(100) comment '类型，agent或者proxy',
`ip` VARCHAR(100) comment 'ip列表，逗号或者空格分开',

`starttime` VARCHAR(20) comment '开始时间',
`finishtime` VARCHAR(20) comment '结束时间',

`status` VARCHAR(100) comment '状态',
`reason` VARCHAR(100) comment '失败理由',
UNIQUE KEY `uniq_uuid_ip` (`uuid`,`ip`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='install_detail';

create table `keepalive`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`slave` VARCHAR(40) comment 'slave',
`time` int(16) unsigned comment 'time',
UNIQUE KEY `uniq_slave` (`slave`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='slave心跳';

create table `check`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',

`projectid` int(16) unsigned comment '项目id',

`user` VARCHAR(100) comment '操作人',
`status` VARCHAR(100) comment '状态',

`slave` VARCHAR(40) comment 'slave',

`last_check` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后检测时间',
`last_success` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后检测成功时间',

`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',

UNIQUE KEY `uniq_projectid` (`projectid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='check';

create table `inherit`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',

`projectid` int(16) unsigned comment '项目id',
`inheritid` int(16) unsigned comment '继承id',

`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',

UNIQUE KEY `uniq_projectid` (`projectid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='inherit';

create table `monitor`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id,仅用于和ip字段做唯一建',
`ip` VARCHAR(100) comment 'agent的ip',
`status` VARCHAR(100) comment '状态',
`fail` int(16) unsigned default 0 comment '失败次数',
`reason` VARCHAR(100) comment '失败原因',
`version` VARCHAR(100) comment '版本',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_projectid_ip` (`projectid`,`ip`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='monitor';
