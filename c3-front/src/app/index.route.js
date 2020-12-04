(function() {
    'use strict';

    angular
        .module('openc3')
        .config(routerConfig);

    /** @ngInject */
    function routerConfig($stateProvider, $urlRouterProvider) {

        $stateProvider
            .state('home', {
                url: '/',
                templateUrl: 'app/main/main.html',
                controller: 'MainController',
                controllerAs: 'main',
                abstract: true
            })
            .state('login', {
                url: '/login',
                templateUrl: 'app/pages/login/login.html',
                controller: 'LoginController',
                controllerAs: 'login',
            })
 
            .state('home.dashboard', {
                url: 'dashboard/:treeid',
                templateUrl: 'app/pages/dashboard/dashboard.html',
                controller: 'DashboardController',
                controllerAs: 'dashboard'
            })

            .state('home.favorites', {
                url: 'favorites/:treeid',
                templateUrl: 'app/pages/favorites/favorites.html',
                controller: 'FavoritesController',
                controllerAs: 'favorites'
            })

//agent
            .state('home.business.agent', {
                url: 'agent/:treeid',
                templateUrl: 'app/pages/business/agent/agent.html',
                controller: 'AgentController',
                controllerAs: 'agent'
            })
//jobx
            .state('home.group', {
                url: 'group/',
                templateUrl: 'app/pages/groupManage/group.html',
                controller: 'GroupController',
                controllerAs: 'group'
            })
            .state('home.business.nodebatch', {
                url: 'nodebatch/:treeid',
                templateUrl: 'app/pages/business/nodebatch/nodebatch.html',
                controller: 'GroupIndexController',
                controllerAs: 'groupindex'
            })

            .state('home.task', {
                url: 'task/',
                templateUrl: 'app/pages/taskManage/task.html',
                controller: 'TaskController',
                controllerAs: 'task'
            })
            .state('home.history.jobx', {
                url: 'jobx/:treeid',
                templateUrl: 'app/pages/history/jobx/jobx.html',
                controller: 'HistoryJobxController',
                controllerAs: 'historyjobx'
            })
            .state('home.quickentry', {
                url: 'quickentry/',
                templateUrl: 'app/pages/quickentry/quickentry.html',
                controller: 'QuickentryController',
                controllerAs: 'quickentry'
            })
 
            .state('home.quickentry.runtask', {
                url: 'runtask/:treeid',
                templateUrl: 'app/pages/quickentry/runtask/runtask.html',
                controller: 'RunTaskController',
                controllerAs: 'runtask'
            })

            .state('home.history.jobxdetail', {
                url: 'jobxdetail/:treeid/:taskuuid',
                templateUrl: 'app/pages/history/jobx/detail/detail.html',
                controller: 'HistoryJobxDetailController',
                controllerAs: 'historyjobxdetail',
                params:{"taskuuid":null, "accesspage":null}
            })
//ci
            .state('home.quickentry.flowline', {
                url: 'flowline/:treeid',
                templateUrl: 'app/pages/quickentry/flowline/flowline.html',
                controller: 'CiGroupController',
                controllerAs: 'cigroup'
            })
 
            .state('home.quickentry.flowlinedetail', {
                url: 'flowlinedetail/:treeid/:projectid',
                templateUrl: 'app/pages/quickentry/flowline/detail/detail.html',
                controller: 'CiController',
                controllerAs: 'ci'
            })
            .state('home.global.ticket', {
                url: 'ticket/:treeid',
                templateUrl: 'app/pages/global/ticket/ticket.html',
                controller: 'TicketController',
                controllerAs: 'ticket'
            })
            .state('home.config', {
                url: 'config/:treeid',
                templateUrl: 'app/pages/config/config.html',
                controller: 'ConfigController',
                controllerAs: 'config'
            })

//job
            // work change
            .state('home.work', {
                url: 'work/',
                templateUrl: 'app/pages/work/work.html',
                controller: 'WorkController',
                controllerAs: 'work'
            })
            .state('home.quickentry.cmd', {
                url: 'cmd/:treeid',
                templateUrl: 'app/pages/quickentry/cmd/cmd.html',
                controller: 'QuickController',
                controllerAs: 'quick'
            })
            .state('home.quickentry.approval', {
                url: 'approval/:treeid',
                templateUrl: 'app/pages/quickentry/approval/approval.html',
                controller: 'QuickApprovalController',
                controllerAs: 'quickapproval'
            })
 
            .state('home.quickentry.scp', {
                url: 'scp/:treeid',
                templateUrl: 'app/pages/quickentry/scp/scp.html',
                controller: 'DistributeController',
                controllerAs: 'distribute'
            })
            .state('home.business.job', {
                url: 'job/:treeid',
                templateUrl: 'app/pages/business/job/job.html',
                controller: 'BusinessJobController',
                controllerAs: 'businessjob'
            })
            .state('home.business.jobcreate', {
                url: 'jobcreate/:treeid',
                templateUrl: 'app/pages/business/job/create.html',
                controller: 'BusinessJobCreateController',
                controllerAs: 'businessjobcreate',
            })
            .state('home.business.jobedit', {
                url: 'jobedit/:treeid',
                templateUrl: 'app/pages/business/job/edit.html',
                controller: 'BusinessJobEditController',
                controllerAs: 'businessjobedit',
                params:{"editjobuuid":null, "editdata":null, "jobtypes":null,"mon_status":null, "mon_ids":null, "editjobname":null,"copyjob":null}
            })
            .state('home.business.jobcopy', {
                url: 'jobcopy/:treeid',
                templateUrl: 'app/pages/business/job/edit.html',
                controller: 'BusinessJobEditController',
                controllerAs: 'businessjobedit',
                params:{"editjobuuid":null, "editdata":null, "jobtypes":null,"mon_status":null, "mon_ids":null, "editjobname":null,"copyjob":null}
            })
            .state('home.history.jobdetail', {
                url: 'jobdetail/:treeid/:taskuuid',
                templateUrl: 'app/pages/history/job/detail/detail.html',
                controller: 'HistoryJobDetailController',
                controllerAs: 'historyjobdetail',
                params:{"taskuuid":null, "jobtype":null, "jobuuid":null}
            })
 
            // flow
            // .state('work', {
            //     url: '/',
            //     templateUrl: 'app/main/main.html',
            //     controller: 'MainController',
            //     controllerAs: 'main',
            //     abstract: true
            // })
            .state('home.business.crontab', {
                url: 'crontab/:treeid',
                templateUrl: 'app/pages/business/crontab/crontab.html',
                controller: 'BusinessCrontabController',
                controllerAs: 'businesscrontab',
            })
            .state('home.history.job', {
                url: 'job/:treeid',
                templateUrl: 'app/pages/history/job/job.html',
                controller: 'HistoryJobController',
                controllerAs: 'historyjob',
            })

            // business
            .state('home.business', {
                url: 'business/',
                templateUrl: 'app/pages/business/business.html',
                controller: 'BusinessController',
                controllerAs: 'business'
            })
            .state('home.business.user', {
                url: 'user/:treeid',
                templateUrl: 'app/pages/business/user/user.html',
                controller: 'UserController',
                controllerAs: 'user'
            })            
            .state('home.business.file', {
                url: 'file/:treeid',
                templateUrl: 'app/pages/business/file/file.html',
                controller: 'FileController',
                controllerAs: 'file'
            })
            .state('home.business.scripts', {
                url: 'scripts/:treeid',
                templateUrl: 'app/pages/business/scripts/script.html',
                controller: 'ScriptsController',
                controllerAs: 'scripts'
            })
            .state('home.business.nodegroup', {
                url: 'nodegroup/:treeid',
                templateUrl: 'app/pages/business/nodegroup/nodegroup.html',
                controller: 'NodeGroupController',
                controllerAs: 'group'
            })
            .state('home.approval', {
                url: 'approval/:treeid',
                templateUrl: 'app/pages/approval/approval.html',
                controller: 'ApprovalController',
                controllerAs: 'approval'
            })
            .state('home.business.machine', {
                url: 'machine/:treeid',
                templateUrl: 'app/pages/business/machine/machine.html',
                controller: 'MachineController',
                controllerAs: 'machine'
            })
            .state('home.connector.node', {
                url: 'node/:treeid',
                templateUrl: 'app/pages/connector/node/node.html',
                controller: 'ConnectorNodeController',
                controllerAs: 'connectornode'
            })
            .state('home.connector.userinfo', {
                url: 'userinfo/:treeid',
                templateUrl: 'app/pages/connector/userinfo/userinfo.html',
                controller: 'ConnectorUserinfoController',
                controllerAs: 'connectoruserinfo'
            })
            .state('home.connector.userauth', {
                url: 'userauth/:treeid',
                templateUrl: 'app/pages/connector/userauth/userauth.html',
                controller: 'ConnectorUserauthController',
                controllerAs: 'connectoruserauth'
            })

            .state('home.history', {
                url: 'history/',
                templateUrl: 'app/pages/history/history.html',
                controller: 'HistoryController',
                controllerAs: 'history'
            })
 
            // connector
            .state('home.connector', {
                url: 'connector/',
                templateUrl: 'app/pages/connector/connector.html',
                controller: 'ConnectorController',
                controllerAs: 'connector'
            })
 
             .state('home.connector.chpasswd', {
                url: 'chpasswd',
                templateUrl: 'app/pages/connector/chpasswd/chpasswd.html',
                controller: 'ConnectorChpasswdController',
                controllerAs: 'connectorchpasswd'
            })
 
             .state('home.connector.mesg', {
                url: 'mesg/:treeid',
                templateUrl: 'app/pages/connector/mesg/mesg.html',
                controller: 'ConnectorMesgController',
                controllerAs: 'connectormesg'
            })

             .state('home.connector.mail', {
                url: 'mail/:treeid',
                templateUrl: 'app/pages/connector/mail/mail.html',
                controller: 'ConnectorMailController',
                controllerAs: 'connectormail'
            })
 
 
            .state('home.connector.tree', {
                url: 'tree/:treeid',
                templateUrl: 'app/pages/connector/tree/tree.html',
                controller: 'ConnectorTreeController',
                controllerAs: 'connectortree'
            })
            .state('home.business.notify', {
                url: 'notify/:treeid',
                templateUrl: 'app/pages/business/notify/notify.html',
                controller: 'AlarmNotifyController',
                controllerAs: 'notify'
            })
            // global
            .state('home.global', {
                url: 'global/',
                templateUrl: 'app/pages/global/global.html',
                controller: 'GlobalController',
                controllerAs: 'global'
            })
            .state('home.global.notify', {
                url: 'notify/:treeid',
                templateUrl: 'app/pages/global/notify/notify.html',
                controller: 'NotifyController',
                controllerAs: 'notify'
            })
            .state('home.global.template', {
                url: 'template/:treeid',
                templateUrl: 'app/pages/global/template/template.html',
                controller: 'TemplateController',
                controllerAs: 'template',
            })
           .state('home.connector.config', {
                url: 'config/:treeid',
                templateUrl: 'app/pages/connector/config/config.html',
                controller: 'ConnectorConfigController',
                controllerAs: 'connectorconfig'
            })
            .state('home.terminal', {
                url: 'terminal/',
                templateUrl: 'app/pages/terminal/terminal.html',
                controller: 'TerminalController',
                controllerAs: 'terminal',
            })
            .state('home.quickentry.terminal', {
                url: 'terminal/:treeid',
                templateUrl: 'app/pages/quickentry/terminal/terminal.html',
                controller: 'TerminalCmdController',
                controllerAs: 'templatecmd',
            })
            .state('home.history.terminal', {
                url: 'terminal/:treeid',
                templateUrl: 'app/pages/history/terminal/terminal.html',
                controller: 'HistoryTerminalController',
                controllerAs: 'historyterminal',
            })
            // end change.
            .state('home.cfg', {
                url: 'cfg/',
                templateUrl: 'app/pages/cfg/cfg.html',
                controller: 'CfgController',
                controllerAs: 'cfg'
            })
            .state('home.cfg.jicheng', {
                url: 'jicheng/:treeid',
                templateUrl: 'app/pages/cfg/tabs/jicheng/jicheng.html',
                controller: 'JichengController',
                controllerAs: 'jicheng'
            })
            .state('home.cfg.bushu', {
                url: 'bushu/:treeid',
                templateUrl: 'app/pages/cfg/tabs/bushu/bushu.html',
                controller: 'BushuController',
                controllerAs: 'bushu'
            })
            .state('home.cfg.yunwei', {
                url: 'yunwei/:treeid',
                templateUrl: 'app/pages/cfg/tabs/yunwei/yunwei.html',
                controller: 'YunweiController',
                controllerAs: 'yunwei'
            })
            //variate query
            .state('home.business.variate', {
                url: "variate/:treeid",
                templateUrl: 'app/pages/business/variate/variate.html',
                controller: 'variateQueryController',
                controllerAs: 'variate'
            })

            .state('home.e401', {
                url:'error/401',
                templateUrl: 'app/pages/others/401.html'
            })
            .state('home.e404', {
                url:'error/404',
                templateUrl: 'app/pages/others/404.html'
            })
            .state('home.e500', {
                url:'error/500',
                templateUrl: 'app/pages/others/500.html'
            })

            .state('log', {
                url: '/api/log/:id',
                templateUrl: 'app/api/log.html',
                controller: 'ApiLogController',
                controllerAs: 'log'
            });


        $urlRouterProvider.otherwise('/dashboard/-1');
    }

})();
