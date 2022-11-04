/* TT基础数据初始化 */

-- impact
insert into openc3_tt_base_impact(level, name, response_sla, resolve_sla) values(1, "Business Critical Function Down",        5, 60 );
insert into openc3_tt_base_impact(level, name, response_sla, resolve_sla) values(2, "Business Critical Function Impaired",   10, 120);
insert into openc3_tt_base_impact(level, name, response_sla, resolve_sla) values(3, "Group Productivity Impaired",           20, 540);
insert into openc3_tt_base_impact(level, name, response_sla, resolve_sla) values(4, "Individual Productivity Impaired",      30, 1080);
insert into openc3_tt_base_impact(level, name, response_sla, resolve_sla) values(5, "Productivity Not Immediately Affected", 60, 1620);

-- category
insert into openc3_tt_base_category(name) values("运维类问题");

-- type
insert into openc3_tt_base_type(name, category_id) values("运维开发", 1);
insert into openc3_tt_base_type(name, category_id) values("基础架构", 1);
insert into openc3_tt_base_type(name, category_id) values("业务运维", 1);
insert into openc3_tt_base_type(name, category_id) values("数据库",   1);
insert into openc3_tt_base_type(name, category_id) values("安全",     1);

-- item
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("资产系统",        1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("单点登录系统",    1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("权限系统",        1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("机器管理系统",    1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("监控系统",        1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("账单系统",        1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("问卷调查系统",    1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("事件管理系统",    1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("变更管理系统",    1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("流程管理系统",    1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("发布系统",        1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("CDN管理系统",     1, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("运维开发其他",    1, "", "");

insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("网络",         2, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("物理服务器",   2, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("存储",         2, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("负载均衡",     2, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("IDC",          2, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("资产数据",     2, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("基础架构其他", 2, "", "");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("监控报警",     2, "", "");

insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("AWS",         3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("金山云",      3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("腾讯云",      3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("其他云主机",  3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("虚拟机服务器",3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("域名",        3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("DNS",         3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("Git",         3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("SVN",         3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("CDN",         3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("监控配置",    3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("短信",        3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("跳板机",      3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("服务器",      3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("Linux",       3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("资产数据",    3,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("业务运维其他",3,"","");

insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("MySQL",     4,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("Redis",     4,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("Memcached", 4,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("MongoDB",   4,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("数据库其他",4,"","");

insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("权限",    5,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("审计",    5,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("漏洞",    5,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("攻击",    5,"","");
insert into openc3_tt_base_item(name, type_id, tpl_title, tpl_content) values("安全其他",5,"","");

-- group
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-Dev", "ops_dev@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org","user004@openc3.org,user005@openc3.org","user006@openc3.org","user007@openc3.org","user008@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, work_day, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-服务台", "group001@openc3.org", "user001@openc3.org", 0, 1440, "0,1,2,3,4,5,6", "user002@openc3.org,user003@openc3.org","user004@openc3.org,user005@openc3.org","user006@openc3.org","user007@openc3.org","user008@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-基础运维", "group001@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org","user004@openc3.org,user005@openc3.org","user006@openc3.org","user007@openc3.org","user008@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-DBA", "group001@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org,user004@openc3.org","user005@openc3.org,user006@openc3.org,user007@openc3.org","user008@openc3.org,user009@openc3.org","user010@openc3.org","user011@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-业务运维-架构资源", "group001@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org,user004@openc3.org","user005@openc3.org,user006@openc3.org,user007@openc3.org","user008@openc3.org,user009@openc3.org","user010@openc3.org","user011@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-业务运维-商业", "group001@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org,user004@openc3.org","user005@openc3.org,user006@openc3.org,user007@openc3.org","user008@openc3.org,user009@openc3.org","user010@openc3.org","user011@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-业务运维-游戏", "group001@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org,user004@openc3.org","user005@openc3.org,user006@openc3.org,user007@openc3.org","user008@openc3.org,user009@openc3.org","user010@openc3.org","user011@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("OPS-业务运维-广告", "group001@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org,user004@openc3.org","user005@openc3.org,user006@openc3.org,user007@openc3.org","user008@openc3.org,user009@openc3.org","user010@openc3.org","user011@openc3.org");
insert into openc3_tt_base_group(group_name, group_email, admin_email, work_hour_start, work_hour_end, level1_report, level2_report, level3_report, level4_report, level5_report) values("云平台-安全", "group001@openc3.org", "user001@openc3.org", 600, 1140, "user002@openc3.org,user003@openc3.org,user004@openc3.org","user005@openc3.org,user006@openc3.org,user007@openc3.org","user008@openc3.org,user009@openc3.org","user010@openc3.org","user011@openc3.org");

-- item-group map
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,1,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,2,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,3,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,4,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,5,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,6,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,7,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,8,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,9,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,10,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,11,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,12,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,13,1);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,14,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,15,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,16,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,17,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,18,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,19,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,20,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(2,21,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,21,2);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,22,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,23,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,24,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,25,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,26,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,27,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,28,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,29,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,30,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,31,1);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(2,32,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(3,32,2);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(1,33,1);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,35,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(6,35,2);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(7,35,3);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(8,35,4);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,36,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(6,36,2);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(7,36,3);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(8,36,4);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,37,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(6,37,2);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(7,37,3);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(8,37,4);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(5,38,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(6,38,2);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(7,38,3);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(8,38,4);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(4,39,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(4,40,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(4,41,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(4,42,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(4,43,1);

insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(9,44,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(9,45,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(9,46,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(9,47,1);
insert into openc3_tt_base_item_group_map(group_id, item_id, priority) values(9,48,1);

-- group user
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user001@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user002@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user003@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user004@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user005@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user006@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user007@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user008@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(1, "user009@openc3.org", 50);

insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user011@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user012@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user013@openc3.org", 5);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user014@openc3.org", 5);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user015@openc3.org", 5);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user016@openc3.org", 5);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user017@openc3.org", 5);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user018@openc3.org", 5);
insert into openc3_tt_base_group_user (group_id, email, priority) values(2, "user019@openc3.org", 50);

insert into openc3_tt_base_group_user (group_id, email, priority) values(3, "user001@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(3, "user021@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(3, "user022@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(3, "user023@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(3, "user024@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(3, "user025@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(3, "user026@openc3.org", 50);

insert into openc3_tt_base_group_user (group_id, email, priority) values(4, "user031@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(4, "user032@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(4, "user033@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(4, "user034@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(4, "user035@openc3.org", 50);
insert into openc3_tt_base_group_user (group_id, email, priority) values(4, "user036@openc3.org", 90);

insert into openc3_tt_base_group_user (group_id, email, priority) values(5, "user041@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(5, "user042@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(5, "user043@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(5, "user044@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(5, "user045@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(5, "user046@openc3.org", 50);
insert into openc3_tt_base_group_user (group_id, email, priority) values(5, "user047@openc3.org", 90);

insert into openc3_tt_base_group_user (group_id, email, priority) values(6, "user051@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(6, "user052@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(6, "user053@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(6, "user054@openc3.org", 50);
insert into openc3_tt_base_group_user (group_id, email, priority) values(6, "user055@openc3.org", 90);

insert into openc3_tt_base_group_user (group_id, email, priority) values(7, "user061@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(7, "user062@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(7, "user063@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(7, "user064@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(7, "user065@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(7, "user066@openc3.org", 50);

insert into openc3_tt_base_group_user (group_id, email, priority) values(8, "user071@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(8, "user072@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(8, "user073@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(8, "user074@openc3.org", 50);
insert into openc3_tt_base_group_user (group_id, email, priority) values(8, "user075@openc3.org", 50);
insert into openc3_tt_base_group_user (group_id, email, priority) values(8, "user076@openc3.org", 90);

insert into openc3_tt_base_group_user (group_id, email, priority) values(9, "user081@openc3.org", 1);
insert into openc3_tt_base_group_user (group_id, email, priority) values(9, "user082@openc3.org", 1);

-- lang
insert into openc3_tt_common_lang(lang,langkey,data) values("简体中文","zh_CN",'{"S":{"Index":{"title":"事件管理系统","cancel":"取消","ok":"确认","view":"查看","submit":"提交","back":"返回","search":"搜索","add":"添加","refresh":"刷新","update":"更新","reset":"重置","save":"保存","delete":"删除","language":"语言","user":"用户","logout":"退出","list":"列表","keyword":"关键词","upload":"上传","download":"下载","export":"导出"},"Menu":{"dashboard":"首页","tt":"事件","create_tt":"新建事件","search_tt":"搜索事件","group_manage":"组管理","my_group":"我的工作组","console":"管理台","i18n_setting":"多国语言设置","impact":"配置Impact与SLA","cti":"配置CTI","workgroup":"配置WorkGroup","email_tpl":"配置邮件模板","system_doc":"系统文档","user_manual":"用户手册","best_practice":"最佳实践"},"Submenu":{"quick_search":"快速搜索","me_not_finish":"指派给我的未完成事件","mygroup_not_finish":"我的解决组的未完成事件","self_submit_not_finish":"我提交的未完成事件","email_me_not_finish":"抄送我的未完成事件","level_12":"级别1-2级的事件(30天内)","myticket":"我的事件"},"TT":{"info":"事件信息","effect":"事件影响","assign":"指派","contact":"联系人","desc":"事件描述","timeout":"已超时","no_timeout":"未超时","resolve_deadline":"解决期限"},"Tab":{"reply":"交流沟通","worklog":"工作记录","solution":"解决方案","syslog":"系统日志"}},"D":{"Base":{"ttno":"事件编号","impact":"影响级别","status":"状态","workgroup":"工作组","group_user":"组员","category":"总类","type":"子类","item":"名目","tt_template":"事件模板","email_template":"邮件模板","title":"标题","content":"详述","attachment":"附件","email_list":"抄送列表","submit_user":"提交人","apply_user":"申请人","response_sla":"响应SLA","resolve_sla":"解决SLA","root_cause":"根本原因","solution":"解决方案","create_time":"创建时间","response_time":"响应时间","resolved_time":"解决时间"},"Impact":{"level1":"关键业务系统失效","level2":"关键业务系统受影响","level3":"部门生产效率受影响","level4":"个人生产效率受影响","level5":"生产效率暂未影响"},"Status":{"assigned":"已指派","wip":"正在处理","pending":"等待","resolved":"已解决","closed":"关闭"}}}');
-- insert into openc3_tt_common_lang(lang,langkey,data) values("简体中文","zh_CN","{}");
insert into openc3_tt_common_lang(lang,langkey,data) values("English","en",'{"S":{"Index":{"title":"Trouble Ticketing","cancel":"Cancel","ok":"OK","view":"Details","submit":"Submit","back":"Back","search":"search","add":"New","refresh":"Refresh","update":"Update","reset":"Reset","save":"Save","delete":"Delete","language":"Language","user":"User","logout":"LogOut","list":"List","keyword":"Keywords","upload":"upload","download":"download","export":"export"},"Menu":{"dashboard":"Dashboard","tt":"Ticket","create_tt":"New Ticket","search_tt":"Search Ticket","group_manage":"Manage Groups","my_group":"My Groups","console":"Control Panel","i18n_setting":"Multiple Language","impact":"Impact&SLA configuration","cti":"CTI configuration","workgroup":"WorkGroup configuration","email_tpl":"Email template configuration","system_doc":"Documents Library","user_manual":"User Manual","best_practice":"Best Practice"},"Submenu":{"quick_search":"Quick Search","me_not_finish":"Unsolved Tickets & Assigned to Me","mygroup_not_finish":"Unsolved Tickets & Assigned to My group","self_submit_not_finish":"Unsolved Tickets & I submit","email_me_not_finish":"Unsolved Tickets & Copy me","level_12":"Impact 1-2 tickets(in 30 days)","myticket":"My Ticket"},"TT":{"info":"Ticket Information","effect":"Impact","assign":"Assigned","contact":"Contacts","desc":"Ticket Description","timeout":"SLA failed","no_timeout":"SLA normal","resolve_deadline":"Resolve Deadline"},"Tab":{"reply":"Reply","worklog":"Work log","solution":"Solution","syslog":"Sys log"}},"D":{"Base":{"ttno":"Ticket Number","impact":"Impact","status":"Status","workgroup":"WorkGroup","group_user":"Group Members","category":"Category","type":"Type","item":"Item","tt_template":"Ticket Template","email_template":"Email Template","title":"Ticket Title","content":"Ticket Description","attachment":"Attachments","email_list":"CC List","submit_user":"Submitter","apply_user":"Applicant","response_sla":"BHRT SLA","resolve_sla":"Resolve SLA","root_cause":"Root cause","solution":"solution","create_time":"assigned time","response_time":"response time","resolved_time":"resolve time"},"Impact":{"level1":"Business Critical Function Down","level2":"Business Critical Function Impaired","level3":"Group Productivity Impaired","level4":"Individual Productivity Impaired","level5":"Productivity Not Immediately Affected"},"Status":{"assigned":"Assigned","wip":"Work in Progress","pending":"Pending","resolved":"Resolved","closed":"Closed"}}}');
--- insert into openc3_tt_common_lang(lang,langkey,data) values("English","en","{}");

-- email template
insert into openc3_tt_base_email_templates(name, description, title, content) values("ticket_submit", "事件提交", "{{.No}} – 提交 – Impact[{{.Impact}}] – Status[{{.Status}}] – {{.Title}}", "submit");
insert into openc3_tt_base_email_templates(name, description, title, content) values("ticket_update", "事件更新", "{{.No}} – 修改 – Impact[{{.Impact}}] – Status[{{.Status}}] – {{.Title}}", "update");
insert into openc3_tt_base_email_templates(name, description, title, content) values("ticket_update_solution", "更新solution", "{{.No}} – Solution – Impact[{{.Impact}}] – Status[{{.Status}}] – {{.Title}}", "solution");
insert into openc3_tt_base_email_templates(name, description, title, content) values("ticket_add_reply", "添加reply", "{{.No}} – 沟通 – Impact[{{.Impact}}] – Status[{{.Status}}] – {{.Title}}", "add reply");
insert into openc3_tt_base_email_templates(name, description, title, content) values("ticket_add_worklog", "添加worklog", "{{.No}} – Worklog – Impact[{{.Impact}}] – Status[{{.Status}}] – {{.Title}}", "add worklog");
insert into openc3_tt_base_email_templates(name, description, title, content) values("ticket_timeout", "SLA超时", "{{.No}} – SLA超时 – Impact[{{.Impact}}] – Status[{{.Status}}] – {{.Title}}", "add worklog");
insert into openc3_tt_base_email_templates(name, description, title, content) values("ticket_closed", "事件关闭", "{{.No}} – 关闭 – Impact[{{.Impact}}] – Status[{{.Status}}] – {{.Title}}", "add worklog");
