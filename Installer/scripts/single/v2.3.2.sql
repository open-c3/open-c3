###数据库发布

use ci;
ALTER TABLE openc3_ci_project ADD `ci_type_open` VARCHAR(20) comment 'open';
ALTER TABLE openc3_ci_project ADD `ci_type_concurrent` VARCHAR(20) comment 'concurrent';
ALTER TABLE openc3_ci_project ADD `ci_type_approver1` VARCHAR(200) comment 'approver1';
ALTER TABLE openc3_ci_project ADD `ci_type_approver2` VARCHAR(200) comment 'approver2';


### 数据库回滚

use ci;
ALTER TABLE openc3_ci_project drop column `ci_type_open`;
ALTER TABLE openc3_ci_project drop column `ci_type_concurrent`;
ALTER TABLE openc3_ci_project drop column `ci_type_approver1`;
ALTER TABLE openc3_ci_project drop column `ci_type_approver2`;
