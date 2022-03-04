###数据库发布

use agent;

create table `openc3_monitor_config_kanban`(
`id`            int(16) unsigned not null primary key auto_increment comment 'id',
`projectid` int(16) unsigned comment '项目id',
`name` VARCHAR(100) comment '名称',
`url` VARCHAR(3000) comment 'url',
`edit_user` VARCHAR(100) comment '编辑者',
`edit_time` TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP comment '创建时间'
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='monitorconfigkanban';

### 数据库回滚

use agent;

drop table openc3_monitor_config_kanban;
