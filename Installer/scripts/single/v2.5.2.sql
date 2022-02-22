###数据库发布

use agent;

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

### 数据库回滚

use agent;

drop table openc3_monitor_self_healing_config;
drop table openc3_monitor_self_healing_task;
