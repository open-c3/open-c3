use connector;
insert into openc3_connector_userinfo (`name`,`pass`)values('open-c3','4cb9c8a8048fd02294477fcb1a41191a');
insert into openc3_connector_userauth(name,level)values('open-c3',3);

insert into openc3_connector_tree(id,name,len)values(10,'open-c3.ops.opsdev.c3_demo',4);
insert into openc3_connector_tree(id,name,len)values(9,'open-c3.ops.opsdev',3);
insert into openc3_connector_tree(id,name,len)values(8,'open-c3.ops',2);
insert into openc3_connector_tree(id,name,len)values(7,'open-c3',1);

insert into openc3_connector_private(id,user)values('4000000001','open-c3');
