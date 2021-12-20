###数据库发布

use ci;

create table `openc3_ci_k8stree`(
`id` int(16) unsigned not null primary key auto_increment comment 'id',
`treeid` int(16) unsigned comment 'treeid',
`k8sid` int(16) unsigned comment 'k8sid',
UNIQUE KEY `uniq_treeid_k8sid` (`treeid`,`k8sid`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8 comment='openc3_ci_k8stree';


ALTER TABLE openc3_ci_ticket ADD `subtype` VARCHAR(100) comment 'subtype';


### 数据库回滚

use ci;

drop table openc3_ci_k8stree;

ALTER TABLE openc3_ci_ticket drop column `subtype`;
