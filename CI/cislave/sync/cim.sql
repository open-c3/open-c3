
replace into openc3_ci_project select * from temp_sync_openc3_ci_project;
delete from openc3_ci_project where id not in (select id from temp_sync_openc3_ci_project );

replace into openc3_ci_images select * from temp_sync_openc3_ci_images;
delete from openc3_ci_images where id not in (select id from temp_sync_openc3_ci_images );

replace into openc3_ci_ticket select * from temp_sync_openc3_ci_ticket;
delete from openc3_ci_ticket where id not in (select id from temp_sync_openc3_ci_ticket );

replace into openc3_ci_cislave_change_event select * from temp_sync_openc3_ci_cislave_change_event;
delete from openc3_ci_cislave_change_event where id not in (select id from temp_sync_openc3_ci_cislave_change_event );
