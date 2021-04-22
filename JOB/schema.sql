create database jobs;
use jobs;

create table `project`(
`id`            int(16) unsigned not null primary key auto_increment  comment 'id',
`status` VARCHAR(100) comment '状态', ###active,inactive

`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '最后编辑时间'

)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='项目';

create table `approval`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`taskuuid` VARCHAR(20) comment '任务编号',
`uuid` VARCHAR(20) comment '唯一编号',
`user` VARCHAR(100) comment '用户名',
`name` VARCHAR(200) comment '审批名',
`submitter` VARCHAR(100) comment '提交人',
`oauuid` VARCHAR(100) comment 'OA单号',
`notifystatus` VARCHAR(100) comment '通知状态', #null sending done skip fail
`cont` VARCHAR(5000) comment '审批内容',
`opinion` VARCHAR(20) comment '审批结果',  ###只允许 agree, refuse, unconfirmed
`remarks` VARCHAR(20) comment '审批标注内容', 
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
`finishtime` VARCHAR(20) comment '结束时间',
UNIQUE KEY `uniq_uuid` (`uuid`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='approval';

###初始化的时候写如一个id为一亿的数据到plugin_approval
create table `plugin_approval`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`jobuuid` VARCHAR(20) comment 'job uuid',
`uuid` VARCHAR(20) comment '唯一编号',
`name` VARCHAR(100) comment '名称',
`cont` VARCHAR(5000) comment '审批内容',
`approver` VARCHAR(300) comment '审批人,多个用逗号分割',
`deployenv` VARCHAR(20) comment '什么时候生效,部署维度',  ###只允许 online, test, always
`action` VARCHAR(20) comment '什么时候生效,动作维度',  ###只允许 deploy, rollback, always
`batches` VARCHAR(20) comment '什么时候生效,分批维度',  ###只允许 firsttime, always
`everyone` VARCHAR(20) comment '是否每个人都需要审批',  ###只允许 on, off
`timeout` VARCHAR(30) comment '超时时间',
`pause` VARCHAR(100) comment '需要暂停',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
#UNIQUE KEY `uniq_jobuuidname` (`jobuuid`,`name`),###因为api在保存作业的时候，是重写写入新的，如果加了这个约束，会使得正在运行的作业找不到插件数据
UNIQUE KEY `uniq_uuid` (`uuid`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='approval插件';

###初始化的时候写如一个id为一亿的数据到plugin_cmd
create table `plugin_cmd`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`jobuuid` VARCHAR(20) comment 'job uuid',
`uuid` VARCHAR(20) comment '唯一编号',
`name` VARCHAR(100) comment '名称',
`user` VARCHAR(20) comment '帐号',
`node_type` VARCHAR(20) comment '节点类型',  ###只允许builtin、group
`node_cont` VARCHAR(2000) comment '节点',
`scripts_type` VARCHAR(32) comment '脚本类型，cite, shell、bat、perl、python',
`scripts_cont` VARCHAR(5000) comment '脚本内容,或引用的编号',
`scripts_argv` VARCHAR(3000) comment '脚本参数',
`timeout` VARCHAR(30) comment '超时时间',
`pause` VARCHAR(100) comment '需要暂停',
`deployenv` VARCHAR(20) comment '什么时候生效,部署维度',  ###只允许 online, test, always
`action` VARCHAR(20) comment '什么时候生效,动作维度',  ###只允许 deploy, rollback, always
`batches` VARCHAR(20) comment '什么时候生效,分批维度',  ###只允许 firsttime, always
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
#UNIQUE KEY `uniq_jobuuidname` (`jobuuid`,`name`),###因为api在保存作业的时候，是重写写入新的，如果加了这个约束，会使得正在运行的作业找不到插件数据
UNIQUE KEY `uniq_uuid` (`uuid`) 
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='cmd插件';

create table `scripts`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',

`projectid` int(16) unsigned comment '项目id',
`name` VARCHAR(100) comment '名称',  ###非空
`type` VARCHAR(32) comment '脚本类型，shell、bat、perl、python',
`cont` VARCHAR(5000) comment '脚本内容',
`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted
UNIQUE KEY `uniq_pn` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='脚本';

###初始化的时候写如一个id为一亿的数据到plugin_scp
create table `plugin_scp`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',

`jobuuid` VARCHAR(20) comment 'job uuid',
`uuid` VARCHAR(20) comment '唯一编号',

`name` VARCHAR(100) comment '名称',
`user` VARCHAR(20) comment '帐号',
`src` VARCHAR(2000) comment '源机器',
`src_type` VARCHAR(20) comment '源机器类型', ###fileserver,builtin,group
`sp` VARCHAR(200) comment '源路径',
`dst` VARCHAR(2000) comment '目标机器',
`dst_type` VARCHAR(20) comment '目标机器类型', ###builtin,group
`dp` VARCHAR(200) comment '目标路径',
`chown` VARCHAR(20) comment 'chown',
`chmod` VARCHAR(20) comment 'chmod',
`timeout` VARCHAR(30) comment '超时时间',
`scp_delete`  VARCHAR(20) comment '减法同步',
`pause` VARCHAR(100) comment '需要暂停',
`deployenv` VARCHAR(20) comment '什么时候生效,部署维度',  ###只允许 online, test, always
`action` VARCHAR(20) comment '什么时候生效,动作维度',  ###只允许 deploy, rollback, always
`batches` VARCHAR(20) comment '什么时候生效,分批维度',  ###只允许 firsttime, always
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
#UNIQUE KEY `uniq_jobuuidname` (`jobuuid`,`name`),###因为api在保存作业的时候，是重写写入新的，如果加了这个约束，会使得正在运行的作业找不到插件数据
UNIQUE KEY `uniq_uuid` (`uuid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='scp插件';

create table `jobs`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment 'projectid',
`uuid` VARCHAR(20) comment '唯一编号',
`name` VARCHAR(100) comment '名称',
`uuids` VARCHAR(300) comment '作业流程编号列表',
`status` VARCHAR(100) DEFAULT 'transient' comment '状态', ###transient,permanent,deleted
`mon_ids` VARCHAR(200) comment '监控节点号',
`mon_status` int(4) unsigned NOT NULL DEFAULT 0 comment '是否允许监控调用',
`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
UNIQUE KEY `uniq_projectidname` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='作业';

create table `crontab`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`name` VARCHAR(100) comment '名称',
`jobuuid` VARCHAR(20) comment 'jobuuid',
`cron` VARCHAR(100) comment '定时规则',
`mutex` VARCHAR(100) comment '互斥',
`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
`status` VARCHAR(100) DEFAULT 'available' comment '状态' ###available,unavailable,deleted
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='定时任务';

create table `crontablock`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`crontabid` int(16) unsigned comment 'crontabid',
`timeid` int(16) unsigned comment 'timeid',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_ctid` (`crontabid`,`timeid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='定时任务锁';

create table `keepalive`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`slave` VARCHAR(40) comment 'slave',
`time` int(16) unsigned comment 'time',
UNIQUE KEY `uniq_slave` (`slave`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='slave心跳';

create table `userlist`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment 'projectid',
`username` VARCHAR(100) comment '帐号',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted

UNIQUE KEY `uniq_projectusername` (`projectid`,`username`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='用户列表';

create table `nodegroup`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',
`name` VARCHAR(100) comment '分组名称',
`plugin` VARCHAR(100) comment '解析插件',
`params` VARCHAR(3000) comment '参数',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted
UNIQUE KEY `uniq_projectidname` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='分组';

create table `task`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',

`uuid` VARCHAR(20) comment '唯一编号',
`name` VARCHAR(100) comment '任务名称',
`user` VARCHAR(100) comment '启动人',
`slave` VARCHAR(40) comment 'slave',
`status` VARCHAR(20) comment '状态',
`starttimems` VARCHAR(20) comment '开始时间包涵毫秒信息',
`finishtimems` VARCHAR(20) comment '结束时间包涵毫秒信息',
`starttime` VARCHAR(20) comment '开始时间',
`finishtime` VARCHAR(20) comment '结束时间',
`calltype` VARCHAR(100) comment '触发类型',
`jobtype` VARCHAR(100) comment '任务类型',
`jobuuid` VARCHAR(100) comment '任务uuid',
`pid` int(16) unsigned comment 'pid',
`runtime` VARCHAR(100) comment '任务总耗时',
`mutex` VARCHAR(100) comment '互斥',
`notify` int(4) unsigned not null default 0 comment '通知状态',
`variable` VARCHAR(4000) comment '私有变量',
`reason` VARCHAR(500) comment '成功/失败的原因',
UNIQUE KEY `uniq_taskid` (`uuid`),
INDEX index_name(`status`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='任务列表';

create table `subtask`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',

`parent_uuid` VARCHAR(20) comment '父任务uuid',
`subtask_type` VARCHAR(20) comment '子任务类型',
`uuid` VARCHAR(20) comment 'uuid',

`nodecount` VARCHAR(20) comment '机器数量',
`starttime` VARCHAR(20) comment '开始时间',
`finishtime` VARCHAR(20) comment '结束时间',
`runtime` VARCHAR(100) comment '任务总耗时',
`status` VARCHAR(20) comment '状态', #runnigs,fail,success,decision,ignore,next

`pause` VARCHAR(20) comment '暂停标志',

UNIQUE KEY `uniq_parentuuid_subtasktype_uuid` (`parent_uuid`,`subtask_type`,`uuid`),
INDEX index_name(`parent_uuid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='子任务列表';


create table `pause`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`taskuuid` VARCHAR(20) comment 'taskid',
`pluginuuid` VARCHAR(20) comment 'pluginid',
`plugin_type` VARCHAR(100) comment '插件类型',
`unlock_user` VARCHAR(100) comment '解锁人',
`unlock_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '解锁时间',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',
UNIQUE KEY `uniq_tpidt` (`taskuuid`,`pluginuuid`,`plugin_type`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='暂停';


create table `fileserver`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',

`name` VARCHAR(200) comment '文件名',
`size` VARCHAR(20) comment '文件大小',
`md5` VARCHAR(40) comment '文件md5',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',

`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted
UNIQUE KEY `uniq_projectid_name` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='文件服务';

create table `variable`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',

`jobuuid` VARCHAR(100) comment 'jobuuid',

`name` VARCHAR(200) comment '变量名称',
`value` VARCHAR(200) comment '变量值',
`describe` VARCHAR(200) comment '变量描述',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',

UNIQUE KEY `uniq_jobuuid_name` (`jobuuid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='作业变量';

create table `notify`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',

`projectid` int(16) unsigned comment '项目id',
`user` VARCHAR(200) comment '用户',

`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',

UNIQUE KEY `uniq_projectid_user` (`projectid`,`user`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='通知人员信息';


create table `environment`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',

`key` VARCHAR(200) comment '名称',
`value` VARCHAR(5000) comment '值',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间',

UNIQUE KEY `uniq_key` (`key`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='作业平台的全局环境变量';

#
#isApiFailEmail:false
#isApiFailSms:false
#isApiSuccessEmail:false
#isApiSuccessSms:false
#isApiWaitingEmail:false
#isApiWaitingSms:false
#isCrontabFailEmail:false
#isCrontabFailSms:false
#isCrontabSuccessEmail:false
#isCrontabSuccessSms:false
#isCrontabWaitingEmail:false
#isCrontabWaitingSms:false
#isPageFailEmail:false
#isPageFailSms:false
#isPageSuccessEmail:false
#isPageSuccessSms:false
#isPageWaitingEmail:false
#isPageWaitingSms:false

#notifyTemplateEmailTitle
#notifyTemplateEmailContent
#notifyTemplateSmsContent

create table `cmdlog`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',

`projectid` int(16) unsigned comment '项目id',

`user` VARCHAR(100) comment '操作人',
`node` VARCHAR(500) comment '机器列表',
`usr` VARCHAR(100) comment '操作帐号',
`cmd` VARCHAR(500) comment '命令',

`time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'

)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='cmdlog';

create table `nodelist`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment 'projectid',
`name` VARCHAR(100) comment '机器名',
`inip` VARCHAR(50) comment '内网ip',
`exip` VARCHAR(50) comment '外网ip',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted

UNIQUE KEY `uniq_projectname` (`projectid`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='机器列表';

create table `token`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment 'projectid',
`token` VARCHAR(50) comment 'token',
`describe` VARCHAR(200) comment '变量描述',
`isjob` VARCHAR(8) comment '是否调用job',
`jobname` VARCHAR(200) comment 'job名称',

`create_user` VARCHAR(100) comment '创建用户',
`create_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '创建时间',
`edit_user` VARCHAR(100) comment '最后编辑用户',
`edit_time` TIMESTAMP NOT NULL DEFAULT '1971-01-01 00:00:00' comment '最后编辑时间',
`status` VARCHAR(100) DEFAULT 'available' comment '状态', ###available,deleted

UNIQUE KEY `uniq_projecttoken` (`projectid`,`token`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='token';

create table `vv`(
`id` int(32) unsigned not null primary key auto_increment comment 'id',
`projectid` VARCHAR(20) comment 'projectid',
`node` VARCHAR(100) comment '机器',
`name` VARCHAR(100) comment '名称',
`value` VARCHAR(100) comment '值',
`update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP comment '更新时间',
UNIQUE KEY `uniq_projectnodename` (`projectid`,`node`,`name`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='版本变量数据';


