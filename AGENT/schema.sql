create database agent;
use agent;

create table `openc3_agent_region`(
`id`            int(16) unsigned not null primary key auto_increment  comment 'id',
`projectid` int(16) unsigned comment '项目id',
`name` VARCHAR(100) comment '区域名称',

`create_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',

UNIQUE KEY `uniq_projectid_name` (`projectid`,`name`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='区域';

create table `openc3_agent_project_region_relation`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',
`regionid` int(16) unsigned comment '区域id',

`create_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_projectid_regionid` (`projectid`,`regionid`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='使用的区域';


create table `openc3_agent_proxy`(
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


create table `openc3_agent_agent`(
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


create table `openc3_agent_install`(
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


create table `openc3_agent_install_detail`(
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

create table `openc3_agent_keepalive`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`slave` VARCHAR(40) comment 'slave',
`time` int(16) unsigned comment 'time',
UNIQUE KEY `uniq_slave` (`slave`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='slave心跳';

create table `openc3_agent_check`(
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

create table `openc3_agent_inherit`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',

`projectid` int(16) unsigned comment '项目id',
`inheritid` VARCHAR(100) comment '继承id',
`fullname` VARCHAR(300) comment '节点全名',

`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',

UNIQUE KEY `uniq_projectid` (`projectid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='inherit';

create table `openc3_agent_monitor`(
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

create table `openc3_monitor_self_healing_config`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`name` VARCHAR(100) comment '自愈套餐名称',
`altername` VARCHAR(100) comment '报警名称',
`jobname` VARCHAR(100) comment '作业名称',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_altername` (`altername`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='monitor_self_healing_config';

create table `openc3_monitor_self_healing_task`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`instance` VARCHAR(100) comment '目标',
`fingerprint` VARCHAR(100) comment 'fingerprint',
`startsAt` VARCHAR(100) comment 'startsAt',
`alertname` VARCHAR(300) comment 'alertname',
`jobname` VARCHAR(100) comment '作业名称',
`taskuuid` VARCHAR(100) comment '作业任务编号',
`taskstat` VARCHAR(100) comment '作业任务状态',
`healingchecktime` VARCHAR(100) comment '自愈状态检查的时间, 大于这个时间',
`healingstat` VARCHAR(100) comment '自愈状态',
`create_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_instance_fingerprint_startsAt_alertname` (`instance`,`fingerprint`,`startsAt`,`alertname`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='monitor_self_healing_task';
