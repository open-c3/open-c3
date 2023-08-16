(function() {
    'use strict';

    angular
        .module('openc3')
        .directive('cmnavbar', cmnavbar);

    /** @ngInject */
    function cmnavbar() {
        var directive = {

            restrict: 'E',
            templateUrl: 'app/components/navbar/navbar.html',
            scope: {},
            controller: NavbarController,
            controllerAs: 'nav'
        };

        return directive;

        /** @ngInject */
        function NavbarController($scope, $location, $http, $state, treeService, $window, ssoService, langService, $translate) {

            var vm = this;
            vm.zTree = '';
            vm.isHovered = false
            treeService.sync.then(function(data) {
      
              vm.zTree = $.fn.zTree.getZTreeObj('openc3tree');
            });
              vm.select_map = {};
              vm.search_init = function () {
                vm.names = [];
                $http.get('/api/connector/connectorx/treemap').success(function (data) {
                  vm.name = data.data;
                  angular.forEach(vm.name, function (value) {
                    vm.names.push(value.name);
                    vm.select_map[value.name] = value.id;
                  });
                });
              };
              /**
               * @typedef {Object} ListItem
               * @property {string} title - 标题
               * @property {string} label - 判断条件标签
               * @property {string} icon - 图标
               * @property {string} router - 路由
               * @property {Object} params - 路由参数
               * @property {string} external - 外部链接
               * @property {string} image - 缺失时图标图片链接
               * @property {Array.<ListItem>} list - 子项列表
               *  @property {string[]} condition - 判断菜单是否展示条件
              */
                /**
                 * @type {Array.<ListItem>}
                */
                vm.menuOption = [
                  // funcOptions
                  {
                    menu: 'C3T.模块',
                    condition:[],
                    options: [
                      // 导航
                      {
                        title: 'C3T.导航',
                        label: '导航',
                        icon: '',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.导航', label: '导航', icon: 'fa fa-compass', router: 'home.search', params: {} },
                        ]
                      },
                      // CMDB
                      {
                        title: 'C3T.CMDB',
                        icon: '',
                        label: 'CMDB',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.CMDB', icon: 'fa fa-database', label: 'CMDB', router: 'home.device.menu', params: {} },
                        ]
                      },
                      // 监控
                      {
                        title: 'C3T.监控',
                        icon: '',
                        router: '',
                        label: '监控',
                        params: {},
                        list: [
                          { title: 'C3T.监控看板', icon: 'fa fa-bar-chart', label: '监控.监控看板', params: {}, router: 'home.quickentry.monitorkanban' },
                          { title: 'C3T.当前告警', icon: 'fa fa-bolt', label: '监控.当前告警', params: {}, router: 'home.allalerts' },
                          { title: 'C3T.监控事件', icon: 'fa fa-envelope', label: '监控.监控事件', params: {}, router: 'home.allcase' },
                          { title: 'C3T.监控配置', icon: 'fa fa-cog', label: '监控.监控配置', params: {}, router: 'home.quickentry.monitorconfig', },
                          { title: 'C3T.报警组管理', icon: 'fa fa-users', label: '监控.报警组管理', params: {}, router: 'home.quickentry.monitorgroup' },
                          { title: 'C3T.值班管理', icon: 'fa fa-calendar', label: '监控.值班管理', params: {}, router: 'home.quickentry.monitoroncall' },
                          { title: 'C3T.监控告警报告', icon: 'fa fa-bell', label: '监控.监控告警报告', params: {}, router: 'home.monreport' },
                          { title: 'C3T.低利用率', icon: 'fa fa-stethoscope', label: '监控.低利用率', params: {}, router: 'home.quickentry.monitornodelow' },
                          { title: 'C3T.邮件监控', icon: 'fa fa-mixcloud', label: '监控.邮件监控', params: {}, router: 'home.quickentry.monitormailmon' },
                          { title: 'C3T.故障自愈', icon: 'fa fa-wheelchair-alt', label: '监控.故障自愈', params: {}, router: 'home.quickentry.selfhealingconfig' },
                        ]
                      },
                      // 流水线
                      {
                        title: 'C3T.流水线',
                        label: '流水线',
                        icon: '',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.流水线', label: '流水线', icon: '', image: '/assets/images/flow-line.png', router: 'home.quickentry.flowline', params: {} },
                        ]
                      },
                      // 快速执行
                      {
                        title: 'C3T.快速执行',
                        icon: '',
                        label: '快速执行',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.启动任务', icon: 'fa fa-play-circle-o', router: 'home.quickentry.runtask', params: {}, label: '快速执行.启动任务' },
                          { title: 'C3T.脚本执行', icon: 'fa fa-code', router: 'home.quickentry.cmd', params: {}, label: '快速执行.脚本执行' },
                          { title: 'C3T.分发文件', icon: 'fa fa-code', router: 'home.quickentry.scp', params: {}, label: '快速执行.分发文件' },
                          { title: 'C3T.发起审批', icon: 'fa fa-calendar-check-o', router: 'home.quickentry.approval', params: {}, label: '快速执行.发起审批' },
                          { title: 'C3T.虚拟终端', icon: 'fa fa-terminal', router: 'home.quickentry.terminal', params: {}, label: '快速执行.虚拟终端' },
                          { title: 'C3T.文件发送', icon: 'fa fa-send-o', router: 'home.quickentry.sendfile', params: {}, label: '快速执行.文件发送' },
                        ]
                      },
                      // 业务管理
                      {
                        title: 'C3T.业务管理',
                        icon: '',
                        label: '业务管理',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.作业管理', label: '业务管理.作业管理', icon: 'fa fa-check-square-o', params: {}, router: 'home.business.job' },
                          { title: 'C3T.账户管理', label: '业务管理.账户管理', icon: 'fa fa-sliders', params: {}, router: 'home.business.user' },
                          { title: 'C3T.文件管理', label: '业务管理.文件管理', icon: 'fa fa-sliders', params: {}, router: 'home.business.file' },
                          { title: 'C3T.脚本管理', label: '业务管理.脚本管理', icon: 'fa fa-sliders', params: {}, router: 'home.business.scripts' },
                          { title: 'C3T.机器分组', label: '业务管理.机器分组', icon: 'fa fa-sliders', params: {}, router: 'home.business.nodegroup' },
                          { title: 'C3T.机器分批', label: '业务管理.机器分批', icon: 'fa fa-sliders', params: {}, router: 'home.business.nodebatch' },
                          { title: 'C3T.机器管理', label: '业务管理.机器管理', icon: 'fa fa-sliders', params: {}, router: 'home.business.machine' },
                          { title: 'C3T.报警通知', label: '业务管理.报警通知', icon: 'fa fa-sliders', params: {}, router: 'home.business.notify' },
                          { title: 'C3T.定时作业', label: '业务管理.定时作业', icon: 'fa fa-clock-o', params: {}, router: 'home.business.crontab' },
                          { title: 'C3T.虚拟服务树管理', label: '业务管理.虚拟服务树管理', icon: 'fa fa-sitemap', params: {}, router: 'home.business.virtual' },
                          { title: 'C3T.代理设置', label: '业务管理.代理设置(AGENT安装)', icon: 'fa fa-gg', params: {}, router: 'home.business.agent' },
                          { title: 'C3T.变量查看', label: '业务管理.变量查看', icon: 'fa fa-list-ul', params: {}, router: 'home.business.variate' },
                          { title: 'C3T.仪表盘', label: '业务管理.仪表盘', icon: 'fa fa-dashboard', params: {}, router: 'home.dashboard' },
                        ]
                      },
                      // 轻应用
                      {
                        title: 'C3T.轻应用',
                        icon: '',
                        label: '轻应用',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.轻应用', icon: 'fa fa-cube', label: '轻应用', router: 'home.quickentry.smallapplication', params: {} }
                        ]
                      },
                      // 容器集群
                      {
                        title: 'C3T.容器集群',
                        icon: '',
                        label: '容器集群',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.kubernetes应用管理', label: '容器集群.kubernetes.应用管理', icon: 'fa fa-cube', params: {}, router: 'home.kubernetesmanage' },
                          { title: 'C3T.AWSECS应用管理', label: '容器集群.AWSECS.应用管理', icon: 'fa fa-cube', params: {}, router: 'home.awsecsmanage' },
                        ]
                      },
                      // 工单
                      {
                        title: 'C3T.工单',
                        icon: '',
                        external: '',
                        label: '工单',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.工单', icon: '', image: '/assets/images/tt-order.png', external: '/tt/', label: '工单', router: '', params: {} },
                        ]
                      },
                      // 其他工具
                      {
                        title: 'C3T.其它工具',
                        icon: '',
                        label: '其它工具',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.其它工具', icon: 'fa fa-wrench', label: '其它工具', router: 'home.thirdparty', params: {} }
                        ]
                      },
                      // BPM
                      {
                        title: 'C3T.BPM',
                        icon: '',
                        label: 'BPM',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.发起新任务', label: 'BPM.发起新任务', icon: 'fa fa-tasks', router: 'home.bpm', params: { bpmuuid: 0 } },
                          { title: 'C3T.我的待办任务', label: 'BPM.我的待办任务', icon: 'fa fa-tasks', router: 'home.history.bpm', params: { type: 'mytask' } },
                          { title: 'C3T.处理过的任务', label: 'BPM.处理过的任务', icon: 'fa fa-tasks', router: 'home.history.bpm', params: { type: 'mylink' } },
                          { title: 'C3T.我发起的任务', label: 'BPM.我发起的任务', icon: 'fa fa-tasks', router: 'home.history.bpm', params: { type: 'myflow' } },
                          { title: 'C3T.全部流程列表', label: 'BPM.全部流程列表', icon: 'fa fa-tasks', router: 'home.history.bpm', params: { type: 'all' } },
                          { title: 'C3T.定时任务列表', label: 'BPM.定时任务列表', icon: 'fa fa-clock-o', params: {}, router: 'home.history.timetask' },
                          { title: 'C3T.流程管理', label: 'BPM.流程管理', icon: 'fa fa-check-square-o', params: {}, router: 'home.business.bpm' },
                        ]
                      },
                      // 执行历史
                      {
                        title: 'C3T.执行历史',
                        icon: '',
                        label: '执行历史',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.分组任务', label: '执行历史.分组任务', icon: 'fa fa-tasks', params: {}, router: 'home.history.jobx' },
                          { title: 'C3T.作业任务', label: '执行历史.作业任务', icon: 'fa fa-pencil-square-o', params: {}, router: 'home.history.job' },
                          { title: 'C3T.虚拟终端', label: '执行历史.虚拟终端', icon: 'fa fa-terminal', params: {}, router: 'home.history.terminal' },
                        ]
                      },
                      // 报告
                      {
                        title: 'C3T.报告',
                        icon: '',
                        label: '报告',
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.GIT', label: '报告.GIT', icon: 'fa fa-gitlab', params: {}, router: 'home.gitreport' },
                          { title: 'C3T.流水线', label: '报告.流水线', icon: 'fa fa-code-fork', params: {}, router: 'home.flowreport' },
                          { title: 'C3T.监控告警', label: '报告.监控告警', icon: 'fa fa-bell', params: {}, router: 'home.monreport' },
                        ]
                      },
                    ]
                  },
                  {
                    menu: 'C3T.管理',
                    condition: ['admin', 'showconnector'],
                    options: [
                      {
                        title: 'C3T.全局信息',
                        icon: '',
                        label: '全局信息',
                        condition: ['admin'],
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.通知管理', label: '', icon: 'fa fa-envelope-o', params: {}, router: 'home.global.notify' },
                          { title: 'C3T.模板管理', label: '', icon: 'fa fa-file-code-o', params: {}, router: 'home.global.template' },
                          { title: 'C3T.系统参数', label: '', icon: 'fa fa-gears', params: {}, router: 'home.global.sysctl' },
                          { title: 'C3T.监控信息', label: '', icon: 'fa fa-line-chart', params: {}, router: 'home.global.monitor' },
                          { title: 'C3T.审计日志', label: '', icon: 'fa fa-calendar-minus-o', params: {}, router: 'home.global.auditlog' },
                          { title: 'C3T.登录审计', label: '', icon: 'fa fa-sign-in', params: {}, router: 'home.global.loginaudit' },
                          { title: 'C3T.轻应用配置', label: '', icon: 'fa fa-cube', params: {}, router: 'home.quickentry.smallapplicationedit' },
                          { title: 'C3T.地址簿管理', label: '', icon: 'fa fa-address-book-o', params: {}, router: 'home.global.useraddr' },
                          { title: 'C3T.ACK管理', label: '', icon: 'fa fa-sliders', params: {}, router: 'home.allack' },
                          { title: 'C3T.监控系统-服务树继承解除', label: '', icon: 'fa fa-bar-chart', params: {}, router: 'home.global.monitortreeunbind' },
                          { title: 'C3T.用户部门关系绑定', label: '', icon: 'fa fa-handshake-o', params: {}, router: 'home.global.userdepartment' },
                          { title: 'C3T.私有节点管理', label: '', icon: 'fa fa-object-ungroup', params: {}, router: 'home.global.private' },
                          { title: 'C3T.CI任务监视器', label: '', icon: 'fa fa-television', params: {}, router: 'home.global.ciwatcher' },
                          { title: 'C3T.网络监视器', label: '', icon: 'fa fa-desktop', params: {}, router: 'home.global.networkmonitor' },
                          { title: 'C3T.管理员审批管理', label: '', icon: 'fa fa-calendar-check-o', params: {}, router: 'home.global.adminapproval' },
                          { title: 'C3T.云监控', label: '', icon: 'fa fa-mixcloud', params: {}, router: 'home.global.cloudmon' },
                          { title: 'C3T.CMDB', label: '', icon: 'fa fa-database', params: {}, router: 'home.global.cmdbmanage' },
                          { title: 'C3T.BPM应用模版管理', label: '', icon: 'fa fa-cube', params: {}, router: 'home.global.k8sapptpl' },
                          { title: 'C3T.跳板机网络管理', label: '', icon: 'fa fa-server', params: {}, router: 'home.global.jumpserverexipsite' },
                          { title: 'C3T.导航管理', label: '', icon: 'fa fa-navicon', params: {}, router: 'home.global.navigation' },
                        ]
                      },
                      // 连接器
                      {
                        title: 'C3T.连接器',
                        icon: '',
                        label: '连接器',
                        condition: ['admin', 'showconnector'],
                        router: '',
                        params: {},
                        list: [
                          { title: 'C3T.设置连接器', label: '设置连接器', icon: 'fa fa-paperclip', params: {}, router: 'home.connector.config' },
                          { title: 'C3T.用户管理', label: '用户管理', icon: 'fa fa-user-plus', params: {}, router: 'home.connector.userinfo' },
                          { title: 'C3T.权限管理', label: '权限管理', icon: 'fa fa-key', params: {}, router: 'home.connector.userauth' },
                          { title: 'C3T.编辑服务树节点', label: '编辑服务树节点', icon: 'fa fa-sitemap', params: {}, router: 'home.connector.tree' },
                          { title: 'C3T.给我的邮件', label: '给我的邮件', icon: 'fa fa-envelope-open-o', params: {}, router: 'home.connector.mail' },
                          { title: 'C3T.给我的短信', label: '给我的短信', icon: 'fa fa-envelope-square', params: {}, router: 'home.connector.mesg' },
                          { title: 'C3T.用户领导管理', label: '用户领导管理', icon: 'fa fa-user-circle-o ', params: {}, router: 'home.connector.userleader' },
                        ]
                      }
                    ]
                  },
          
                ]

            vm.handleStateGo = function (event, item) {
              event.stopPropagation();
              
              if (item && item.external) {
                window.open(item.external)
              }
              if (!item.router) {
                return
              }
              $state.go(item.router, Object.assign({treeid:$state.params.treeid}, item.params))
              vm.isHovered = false
            }

            vm.handleCondition = function (userInfo, value) {
              if (value && userInfo) {
                return value.every(item => userInfo[item] == 1)
              }
            };

            vm.searchNode = function (item, model, label, event){
              var node = vm.zTree.getNodeByParam("id", vm.select_map[item]);
              vm.zTree.selectNode(node);
              vm.zTree.expandNode(node);
              vm.search_init(event)
            };

            vm.clearAllCookies = function() {
              const cookies = document.cookie.split(";");
              for (let i = 0; i < cookies.length; i++) {
                const cookie = cookies[i];
                const eqPos = cookie.indexOf("=");
                const name = eqPos > -1 ? cookie.substr(0, eqPos) : cookie;
                document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/";
              }
            }

            $scope.envir = 'test';
            $scope.allUrls = [ ];
            $scope.nextUrls = { };
            $scope.mulUrls = { };
            $scope.ciUrls = { };
            vm.logout = function(){
                var siteaddr = window.location.protocol + '//' + window.location.host;
                $http.get('/api/connector/connectorx/ssologout?siteaddr=' + siteaddr ).success(function(data){
                    vm.clearAllCookies()
                    if(data.data)
                    {
                        $window.location.href=data.data
                    }
                    else
                    {
                        $window.location.reload();
                    }
                });
            };

            vm.chpasswd = function(){
                var siteaddr = window.location.protocol + '//' + window.location.host;
                $window.location.href=ssoService.chpasswd + '?siteaddr=' + siteaddr ;
            };

            vm.state = $state;
            vm.state.params.treeid = vm.state.params.treeid ? vm.state.params.treeid : 4000000000;

            // get user
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.user = data;
                sessionStorage.setItem('userInfo', JSON.stringify(data))
            });

            var hash = $location.host();
            var envir = hash.split(".")[0];
            var envir_name = hash.split(".")[1];

            if (envir == 'dev' || envir == 'test'){
                $scope.envir = 'test';
            }else{
                $scope.envir = 'online';
            }

            vm.openCI = function (idx, next_name) {
                var ciurl = $scope.ciUrls[$scope.envir][idx].url + "/#/search/" + vm.state.params.treeid;
                if ($scope.envir == "test"){
                    window.open(ciurl, '_blank');
                    return
                }
                if (envir != next_name){
                    window.open(ciurl, '_blank')
                }else {
                    return
                }

            };
            vm.openMul = function (idx, next_name) {
                var ciurl = $scope.mulUrls[$scope.envir][idx].url + vm.state.params.treeid;
                if ($scope.envir == "test"){
                    window.open(ciurl, '_blank');
                    return
                }
                if (envir != next_name){
                    window.open(ciurl, '_blank')
                }else {
                    return
                }
            };
            vm.openUrl = function (idx, next_name) {
                var nextUrl = '';
                window.open(nextUrl, '_blank')
            }

          // language
          langService.getData().then(function(data){
              vm.langData = data;
          });

          vm.changeLang = function(key){
              $translate.use(key);
              vm.currentLang = $translate.proposedLanguage() || $translate.use();
          };


          vm.toggleCard = function (type) {
            if (type) {
              vm.isHovered = type
            }
            vm.isHovered = !vm.isHovered
          }
        }
    }

})();
