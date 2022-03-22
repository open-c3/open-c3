###数据库发布

use agent;
ALTER TABLE openc3_monitor_self_healing_config ADD `eips` VARCHAR(500) comment '生效的ip列表';


### 数据库回滚

use agent;
ALTER TABLE openc3_monitor_self_healing_config drop column `eips`;
