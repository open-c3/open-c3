use ci;

drop table openc3_ci_favorites;
drop table openc3_ci_images;
drop table openc3_ci_keepalive;
drop table openc3_ci_project;
drop table openc3_ci_rely;
drop table openc3_ci_repository;
drop table openc3_ci_ticket;
drop table openc3_ci_version;

use jobs;
drop table `openc3_job_approval`;
drop table `openc3_job_cmdlog`;
drop table `openc3_job_crontab`;
drop table `openc3_job_crontablock`;
drop table `openc3_job_environment`;
drop table `openc3_job_fileserver`;
drop table `openc3_job_jobs`;
drop table `openc3_job_keepalive`;
drop table `openc3_job_nodegroup`;
drop table `openc3_job_nodelist`;
drop table `openc3_job_notify`;
drop table `openc3_job_pause`;
drop table `openc3_job_plugin_approval`;
drop table `openc3_job_plugin_cmd`;
drop table `openc3_job_plugin_scp`;
drop table `openc3_job_project`;
drop table `openc3_job_scripts`;
drop table `openc3_job_smallapplication`;
drop table `openc3_job_subtask`;
drop table `openc3_job_task`;
drop table `openc3_job_token`;
drop table `openc3_job_userlist`;
drop table `openc3_job_variable`;
drop table `openc3_job_vv`;

use jobx;
drop table `openc3_jobx_flowline_version`;
drop table `openc3_jobx_group`;
drop table `openc3_jobx_group_type_list`;
drop table `openc3_jobx_group_type_percent`;
drop table `openc3_jobx_keepalive`;
drop table `openc3_jobx_monitor`;
drop table `openc3_jobx_subtask`;
drop table `openc3_jobx_task`;


use agent;
drop table `openc3_agent_agent`;
drop table `openc3_agent_check`;
drop table `openc3_agent_inherit`;
drop table `openc3_agent_install`;
drop table `openc3_agent_install_detail`;
drop table `openc3_agent_keepalive`;
drop table `openc3_agent_monitor`;
drop table `openc3_agent_project_region_relation`;
drop table `openc3_agent_proxy`;
drop table `openc3_agent_region`;

use connector;
drop table `openc3_connector_auditlog`;
drop table `openc3_connector_group`;
drop table `openc3_connector_group_type_list`;
drop table `openc3_connector_group_type_percent`;
drop table `openc3_connector_keepalive`;
drop table `openc3_connector_log`;
drop table `openc3_connector_nodelist`;
drop table `openc3_connector_subtask`;
drop table `openc3_connector_task`;
drop table `openc3_connector_tree`;
drop table `openc3_connector_userauth`;
drop table `openc3_connector_userinfo`;
drop table `openc3_connector_usermail`;
drop table `openc3_connector_usermesg`;

