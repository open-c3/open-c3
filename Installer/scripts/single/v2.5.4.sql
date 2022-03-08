###数据库发布

use agent;

ALTER TABLE openc3_monitor_config_kanban ADD `default` int(4) unsigned default 0 comment '默认模版';


### 数据库回滚

use agent;

ALTER TABLE openc3_monitor_config_kanban drop column `default`;
