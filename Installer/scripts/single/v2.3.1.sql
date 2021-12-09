###数据库发布

use ci;
ALTER TABLE openc3_ci_project ADD `ci_type` VARCHAR(100) DEFAULT 'default' comment 'citype';
ALTER TABLE openc3_ci_project ADD `ci_type_ticketid` VARCHAR(20) comment 'k8sticketid';
ALTER TABLE openc3_ci_project ADD `ci_type_kind` VARCHAR(200) comment 'k8s.kind';
ALTER TABLE openc3_ci_project ADD `ci_type_namespace` VARCHAR(200) comment 'k8snamespace';
ALTER TABLE openc3_ci_project ADD `ci_type_name` VARCHAR(200) comment 'name';
ALTER TABLE openc3_ci_project ADD `ci_type_container` VARCHAR(200) comment 'container';
ALTER TABLE openc3_ci_project ADD `ci_type_repository` VARCHAR(200) comment 'repository';
ALTER TABLE openc3_ci_project ADD `ci_type_dockerfile` VARCHAR(200) comment 'dockerfile';
ALTER TABLE openc3_ci_project ADD `ci_type_dockerfile_content` VARCHAR(3000) comment 'dockerfile_content';

alter table openc3_ci_ticket modify `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP; #如果这条报错请忽略,mysql版本不一样
alter table openc3_ci_ticket modify column `share` VARCHAR(5000);


### 数据库回滚

use ci;
ALTER TABLE openc3_ci_project drop column `ci_type`;
ALTER TABLE openc3_ci_project drop column `ci_type_ticketid`;
ALTER TABLE openc3_ci_project drop column `ci_type_kind`;
ALTER TABLE openc3_ci_project drop column `ci_type_namespace`;
ALTER TABLE openc3_ci_project drop column `ci_type_name`;
ALTER TABLE openc3_ci_project drop column `ci_type_container`;
ALTER TABLE openc3_ci_project drop column `ci_type_repository`;
ALTER TABLE openc3_ci_project drop column `ci_type_dockerfile`;
ALTER TABLE openc3_ci_project drop column `ci_type_dockerfile_content`;

alter table openc3_ci_ticket modify column `share` VARCHAR(100);
