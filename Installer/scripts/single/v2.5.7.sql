###数据库发布

use jobs;

ALTER TABLE openc3_job_variable ADD `option` VARCHAR(1000) comment '选项列表';

### 数据库回滚

use jobs;

ALTER TABLE openc3_job_variable drop column `option`;
