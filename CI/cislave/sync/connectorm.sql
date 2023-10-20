
replace into openc3_connector_userinfo select * from temp_sync_openc3_connector_userinfo;
delete from openc3_connector_userinfo where id not in (select id from temp_sync_openc3_connector_userinfo );

replace into openc3_connector_userauth select * from temp_sync_openc3_connector_userauth;
delete from openc3_connector_userauth where id not in (select id from temp_sync_openc3_connector_userauth );

replace into openc3_connector_tree select * from temp_sync_openc3_connector_tree;
delete from openc3_connector_tree where id not in (select id from temp_sync_openc3_connector_tree );
