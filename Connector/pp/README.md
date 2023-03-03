# c3mc工具说明/x

用途说明:
```
c3mc-agent-inherit:             无需参数，执行过程会把treemap刷到db中做继承关系。由服务定时调用。
c3mc-agent-network-check:       调用进行agent网络检查,定时任务会调用它每晚执行。
c3mc-agent-network-check-flow:  c3mc-agent-network-check会调用。
c3mc-agent-network-check-once:  c3mc-agent-network-check会调用。

c3mc-app:                       app bash
c3mc-app-awscli-get:            通过ticketid获取awscli
c3mc-app-findtags:              通过flowid执行一次findtag
c3mc-app-merge-report:          合并服务树节点中的报告
c3mc-app-online:                操作应用上下线
c3mc-app-port-checkok:          检查服务的监控端口是否返回正常，异常时重启服务。
c3mc-app-supervisormin:         守护脚本
c3mc-app-usrext:                扩展用户

c3mc-aws-ecs-describe:          获取ECS服务的描述
c3mc-base-approval-create:      创建审批
c3mc-base-approval-query:       查询审批结果
c3mc-base-audit:                审计日志
c3mc-base-cleandisk:            清理磁盘
c3mc-base-configx:              获取c3的config.ini配置
c3mc-base-count-limit:          限制输出行数
c3mc-base-db-exe:               执行sql
c3mc-base-db-get:               sql查询
c3mc-base-db-ins:               插入数据
c3mc-base-db-set:               更新数据
c3mc-base-dumpfile:             数据dump到文件中，保持原子操作
c3mc-base-fullnodeinfo:         获取服务树节点数据，包括JOB中的机器管理部分
c3mc-base-git:                  可以指定key的git命令
c3mc-base-hostexip
c3mc-base-hostname
c3mc-base-log-addtime
c3mc-base-log-addtimemin
c3mc-base-nodeinfo:             获取服务树节点数据
c3mc-base-role:                 获取节点role
c3mc-base-send:                 发送消息
c3mc-base-sendcall:             发送语音
c3mc-base-sendmail:             发送邮件
c3mc-base-sendmesg:             发送短信
c3mc-base-task-grep:            任务过滤
c3mc-base-treemap
c3mc-base-tree-switch:          服务树id切换，在连接器同时使用多个树的情况下使用。

c3mc-ci-bury:                   ci清理异常任务
c3mc-ci-clean:                  ci清理临时数据
c3mc-ci-flowreport:             流水线报告
c3mc-ci-flowreport-cireport
c3mc-ci-flowreport-jobxreport
c3mc-ci-gitreport:              git报告
c3mc-ci-gitreport-cron
c3mc-ci-gitreport-once
c3mc-ci-gitreport-statistics
c3mc-ci-gitreport-sync
c3mc-ci-project-show
c3mc-ci-status-up
c3mc-ci-tag-grep:
c3mc-ci-tag-ls:
c3mc-ci-tag-ls-git
c3mc-ci-tag-ls-harbor
c3mc-ci-tag-ls-svn
c3mc-ci-tag-save:

c3mc-cloudmon-make-promesd
c3mc-cloudmon-make-task:

c3mc-code-tree
c3mc-docker-buildandsave
c3mc-docker-save:
c3mc-flow-nsctl-copy
c3mc-flow-nsctl-copy-job
c3mc-flow-nsctl-copy-jobx
c3mc-flow-nsctl-delete
c3mc-install:               安装c3mc

c3mc-job-approval-create: job审批创建
c3mc-job-approval-query
c3mc-job-environment
c3mc-job-slave-random
c3mc-job-task-run
c3mc-job-task-stat

c3mc-jobx-slave-random
c3mc-jobx-task-info-bysubuuid
c3mc-jobx-task-run
c3mc-jobx-task-stat

c3mc-k8s-backup
c3mc-k8s-backup-cron
c3mc-k8s-backup-once
c3mc-k8s-kubectl-get
c3mc-k8s-kubectl-getallresource
c3mc-k8s-node-taint
c3mc-k8s-nsctl-copy
c3mc-k8s-nsctl-dump: dump k8s ns

c3mc-login
c3mc-login-ldap
c3mc-login-mysql

c3mc-mon-agent-install
c3mc-mon-agent-install-errnode
c3mc-mon-carry
c3mc-mon-mailmon-addcont
c3mc-mon-mailmon-adduser
c3mc-mon-mailmon-format
c3mc-mon-mailmon-record
c3mc-mon-mailmon-sender
c3mc-mon-mailmon-syncer
c3mc-mon-mesg-addcont
c3mc-mon-mesg-adduser
c3mc-mon-mesg-format
c3mc-mon-mesg-merge
c3mc-mon-monreport
c3mc-mon-monreport-cron
c3mc-mon-monreport-make
c3mc-mon-mysql-exporterclean
c3mc-mon-mysql-exportermaker
c3mc-mon-mysql-sdformat
c3mc-mon-nodename-get
c3mc-mon-nodesd-format
c3mc-mon-nodetree-get
c3mc-mon-proxy
c3mc-mon-redis-exporterclean
c3mc-mon-redis-exportermaker
c3mc-mon-redis-sdformat
c3mc-mon-rule
c3mc-mon-selfhealing-curralter
c3mc-mon-selfhealing-grepeips
c3mc-mon-selfhealing-maketask
c3mc-mon-selfhealing-runtask
c3mc-mon-selfhealing-update
c3mc-mon-selfhealing-updatetask
c3mc-mon-sender
c3mc-mon-treeinfo

c3mc-oncall-cal
c3mc-oncall-list
c3mc-oncall-make
c3mc-oncall-now
c3mc-oncall-zone

c3mc-server-agent
c3mc-server-ci
c3mc-server-job
c3mc-server-jobx

c3mc-sys-backup
c3mc-sys-ctl
c3mc-sys-dup

c3mc-app-ipsearch:       在cache中查询ip的外网地址和主机名
c3mc-app-ipfill:         把标准输入中包含ip地址的字符串替换成主机详细信息
c3mc-app-okfill:         把标准输入中包含ip地址的字符串，添加上65110端口的检测结果
c3mc-app-mon-proxy-show: 获取0号节点代理配置信息,主要针对监控系统
```
