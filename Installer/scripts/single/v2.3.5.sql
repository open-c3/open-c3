###数据库发布

use ci;

ALTER TABLE openc3_ci_project ADD `audit_level` VARCHAR(2) DEFAULT '0' comment 'audit_level';


### 数据库回滚

use ci;

ALTER TABLE openc3_ci_project drop column `audit_level`;
