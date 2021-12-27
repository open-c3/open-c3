###数据库发布

use jobs;

ALTER TABLE openc3_job_plugin_approval ADD `relaxed` VARCHAR(20) default 'off' comment 'relaxed';


### 数据库回滚

use jobs;

ALTER TABLE openc3_job_plugin_approval drop column `relaxed`;
