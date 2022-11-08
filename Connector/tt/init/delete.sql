use connector;

SET foreign_key_checks = 0;

delete from openc3_tt_base_category;
delete from openc3_tt_base_email_templates;
delete from openc3_tt_base_group;
delete from openc3_tt_base_group_user;
delete from openc3_tt_base_impact;
delete from openc3_tt_base_item;
delete from openc3_tt_base_item_group_map;
delete from openc3_tt_base_type;
delete from openc3_tt_common_lang;
delete from openc3_tt_common_reply_log;
delete from openc3_tt_common_sys_log;
delete from openc3_tt_common_work_log;
delete from openc3_tt_ticket;
delete from openc3_tt_ticket_attachment;

truncate table openc3_tt_base_category;
truncate table openc3_tt_base_email_templates;
truncate table openc3_tt_base_group;
truncate table openc3_tt_base_group_user;
truncate table openc3_tt_base_impact;
truncate table openc3_tt_base_item;
truncate table openc3_tt_base_item_group_map;
truncate table openc3_tt_base_type;
truncate table openc3_tt_common_lang;
truncate table openc3_tt_common_reply_log;
truncate table openc3_tt_common_sys_log;
truncate table openc3_tt_common_work_log;
truncate table openc3_tt_ticket;
truncate table openc3_tt_ticket_attachment;

