(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorConfigController', MonitorConfigController)
        .filter('cut60', function () {
            return function (text) {
                if( text.length > 63 )
                {
                    return "..." + text.substr(text.length - 60)
                }
                return text;

            }
        });

    function MonitorConfigController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.usersign = '';

        vm.dashboarnuuid1 = 'dUrNraOn1';
        vm.dashboarnuuid2 = 'dUrNraOnz';

        vm.alias = { 'port': '端口', 'process': '进程', 'http': 'HTTP', 'tcp': 'TCP','udp': 'UDP', 'path': '路径' }
        vm.locked = 0;
        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();

            if( vm.locked == 1 )
            {
                return;
            }

            var xx = vm.nodeStr.split(".").length;
            if( xx <= 2 )
            {
                vm.seturl( vm.dashboarnuuid1, '_host_' );
            }
            else
            {
                vm.seturl( vm.dashboarnuuid2, '_host_' );
            }
            document.getElementById('frame_id').contentWindow.location.reload();
        });

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.seturl = function( uuid, name )
        {
            if( name == '_host_' )
            {
                vm.url = vm.siteaddr + '/third-party/monitor/grafana/d/' + uuid + '/openc3-dashboard?orgId=1&var-origin_prometheus=&var-job=openc3&var-hostname=All&var-device=All&var-interval=2m&var-maxmount=&var-show_hostname=&var-total=1&var-treeid=treeid_' + vm.treeid + '&kiosk';
            }
            else
            {
                vm.url = vm.siteaddr + '/third-party/monitor/grafana/d/7h8Ok7wGz/k8sji-qun-jian-kong-kan-ban-hui-zong?orgId=1&var-datasource=thanos&var-cluster=' + name + '&var-namespace=All&var-pod=alertmanager-server-679c879455-x7vww&var-interval=$__auto_interval_interval&var-container=alertmanager&var-node=All&var-k8s_version=v1.19.6-eks-49a6c0&kiosk';
            }
        }

        vm.seturl( vm.dashboarnuuid1, '_host_' );
        vm.prometheusurl = vm.siteaddr + '/third-party/monitor/prometheus/alerts';
        vm.alertmanagerurl = vm.siteaddr + '/third-party/monitor/alertmanager/#/alerts?silenced=false&inhibited=false&active=true&filter=%7Bfromtreeid%3D"' + vm.treeid + '"%7D';
        vm.grafanaurl = vm.siteaddr + '/third-party/monitor/grafana/';

        vm.openNewWindow = function( url )
        {
            window.open( url, '_blank')
        }

        vm.trustSrc = function()
        {
            if( vm.nodeStr === undefined )
            {
                return;
            }
            return $sce.trustAsResourceUrl( vm.url );
        }

        vm.choiceKanban = '_host_';
        vm.changeKanban = function()
        {
            if( vm.choiceKanban == '_host_' )
            {
                var xx = vm.nodeStr.split(".").length;
                if( xx <= 2 )
                {
                    vm.seturl( vm.dashboarnuuid1, '_host_' );
                }
                else
                {
                    vm.seturl( vm.dashboarnuuid2, '_host_' );
                }
            }
            else
            {
                vm.url = vm.choiceKanban;
            }

            document.getElementById('frame_id').contentWindow.location.reload();
        }

        vm.monitorgroup = [];
        vm.monitoroncall = [];

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/monitor/config/collector/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeRegionTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载采集列表失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.reloadRule = function(){
            vm.loadoverRule = false;
            $http.get('/api/agent/monitor/config/rule/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeRuleTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadoverRule = true;
                } else { 
                    toastr.error( "加载监控策略失败:" + data.info )
                }
            });
        };

        vm.reloadRule();

        vm.reloadNodeinfo = function(){
            vm.loadoverNodeinfo = false;
            $http.get('/api/agent/nodeinfo/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeNodeinfoTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadoverNodeinfo = true;
                } else { 
                    toastr.error( "加载Nodeinfo失败:" + data.info )
                }
            });
        };

        vm.reloadNodeinfo();

        vm.reloadAlert = function(){
            vm.loadoverAlert = false;
            $http.get('/api/agent/monitor/alert/' + vm.treeid + "?siteaddr=" + vm.siteaddr ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeAlertTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadoverAlert = true;
                } else { 
                    toastr.error( "加载当前告警失败:" + data.info )
                }
            });
        };

        var openc3_demo_version_only=0;

        if( openc3_demo_version_only == 0 )
        {
            vm.reloadAlert();
        }
        vm.reloadUser = function(){
            vm.loadoverUser = false;
            $http.get('/api/agent/monitor/config/user/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeUserTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadoverUser = true;
                } else { 
                    toastr.error( "加载报警接收人失败:" + data.info )
                }
            });

            $http.get('/api/agent/monitor/config/group' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.monitorgroup = data.data
                } else { 
                    toastr.error( "加载监控组列表失败:" + data.info )
                }
            });
 
            $http.get('/api/agent/monitor/config/oncall' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.monitoroncall = data.data;
                } else { 
                    toastr.error( "加载监控组列表失败:" + data.info )
                }
            });
 
        };

        vm.reloadUser();

        vm.createCollector = function (postData, title) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorconfig/create/collector.html',
                controller: 'CreateMonitorConfigController',
                controllerAs: 'createMonitorConfig',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload},
                    title: function(){ return title},
                    postData: function(){ return postData}
                }
            });
        };

        vm.createRule = function (postData, title) {

            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorconfig/create/rule.html',
                controller: 'CreateMonitorConfigRuleController',
                controllerAs: 'createMonitorConfigRule',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reloadRule},
                    title: function(){ return title},
                    postData: function(){ return postData}
                }
            });
        };

        vm.tplSyncRule = function () {

            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorconfig/tpl/sync.html',
                controller: 'TplSyncMonitorConfigRuleController',
                controllerAs: 'tplSyncMonitorConfigRule',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reloadRule},
                }
            });
        };
 
        vm.tplSaveRule = function () {

            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorconfig/tpl/save.html',
                controller: 'TplSaveMonitorConfigRuleController',
                controllerAs: 'tplSaveMonitorConfigRule',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reloadRule},
                }
            });
        };
 
        vm.copyRule = function (postData, title) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorconfig/copy/rule.html',
                controller: 'CopyMonitorConfigRuleController',
                controllerAs: 'copyMonitorConfigRule',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reloadRule},
                    title: function(){ return title},
                    postData: function(){ return postData}
                }
            });
        };

        vm.createUser = function () {
            vm.newuser = $scope.newUser;
            if ( vm.newuser != undefined && vm.newuser.length > 0){
                $http.post('/api/agent/monitor/config/user/' + vm.treeid, {'user': vm.usersign + vm.newuser }).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            vm.reloadUser();
                            $scope.newUser = '';
                        }else {
                            toastr.error( "添加失败：" + response.data.info );
                        }
                    },
                    function errorCallback (response ){
                        toastr.error( "添加失败：" + response.status );
                    }
                );
            }
        };

         vm.testsend = function ( user ) {
            $http.post('/api/agent/monitor/config/usertest', { projectid: vm.treeid, 'user': user}).then(
                function successCallback(response) {
                    if (response.data.stat){
                        swal({title: "消息发送已经提交！", text: "确认是否收到消息", type: 'success'});
                    }else {
                        toastr.error( "发送消息失败：" + response.data.info );
                    }
                },
                function errorCallback (response ){
                    toastr.error( "发送消息添加失败：" + response.status );
                }
            );
        };



        vm.deleteCollector = function(id) {
          swal({
            title: "是否要删除该指标采集",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/collector/' + vm.treeid + '/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除监控采集失败:" + date.info)}
                vm.reload();
            });
          });
        }

        vm.cleanRule = function() {
          swal({
            title: "清空本节点监控策略",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/rule/' + vm.treeid ).success(function(data){
                if( ! data.stat ){ toastr.error("删除监控策略:" + date.info)}
                vm.reloadRule();
            });
          });
        }

        vm.deleteRule = function(id) {
          swal({
            title: "是否要删除该监控策略",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/rule/' + vm.treeid + '/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除监控策略:" + date.info)}
                vm.reloadRule();
            });
          });
        }

        vm.deleteUser = function(id) {
          swal({
            title: "是否要删除该用户",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/user/' + vm.treeid + '/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除报警接收人失败:" + date.info)}
                vm.reloadUser();
            });
          });
        }

        vm.kanbanConfig = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorconfig/kanbanconfig.html',
                controller: 'KanbanConfigController',
                controllerAs: 'kanbanconfig',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    homereload: function () { return vm.reload},
                }
            });
        };

        vm.getinstancename = function( labels ) {
            var name = labels['instance'];
            
            if( labels['instanceid'] )
            {
                name = labels['instanceid'];
            }

            if( labels['cache_cluster_id'] )
            {
                name = labels['cache_cluster_id'];
            }

            return name;
        };

        vm.checkoldstatus=false;
        vm.checknewstatus=false;
        vm.reloadcheck = function(){
            $http.get('/api/agent/monitor/config/treeunbind/' + vm.treeid ).success(function(data){
                vm.checkstatusloadover = true;
                vm.checkstatusdata = data.data;
                if(  data.data.status )
                {
                    vm.checkoldstatus=true;
                    vm.checknewstatus=true;
                }
                else
                {
                    vm.checkoldstatus=false;
                    vm.checknewstatus=false;
                }
            });
        };

        vm.reloadcheck();

        vm.savecheckstatus = function(){
          swal({
            title: "保存新状态",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            vm.checkstatus = '0';
            if( vm.checknewstatus == true)
            {
                vm.checkstatus = '1';
            }
            $http.post('/api/agent/monitor/config/treeunbind/' + vm.treeid, { status: vm.checkstatus} ).success(function(data){
                if(data.stat == true)
                {
                    swal({ title: "修改成功!", type:'success' });
                    vm.checkoldstatus= vm.checknewstatus;
                } else {
                    swal({ title: "修改失败!", text: data.info, type:'error' });
                }
            })

          })
        }

    }
})();
