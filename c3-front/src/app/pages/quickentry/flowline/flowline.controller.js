(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CiGroupController', CiGroupController);

    function CiGroupController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.time2date = genericService.time2date
        var toastr = toastr || $injector.get('toastr');

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        $scope.panelcolor = { "success": "green", "fail": "red", "refuse": "orange",  "running": "#98b2bc", "decision": "#aaa", "ignore": "#aaa" }

        vm.versiondetail = function (id) {
            $state.go('home.quickentry.flowlinedetail', {treeid:vm.treeid, projectid: id});
        };

        vm.editconfig = function (id,name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/detail/config.html',
                controller: 'ConfigController',
                controllerAs: 'config',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    getGroup: function () {return vm.getGroupInfo},
                    projectid: function () {return id},
                    treeid: function () {return vm.treeid},
                    name: function () {return name},
                    groupid: function () {},
                }
            });
        };

        vm.flowlinecount = 0;
        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/ci/group/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeRegionTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.flowlinecount = data.data.length
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载版本失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.showlog = function(versionuuid,slave){
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/showlog.html',
                controller: 'CiShowLogController',
                controllerAs: 'showlog', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                windowClass:'modal-class',
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    reloadhome: function () { return vm.reload },
                    versionuuid: function () { return versionuuid },
                    slave: function () { return slave }
                }
            });
        };

        vm.deployDetail = function(uuid){
            $state.go('home.history.jobxdetail', {treeid:vm.treeid, taskuuid:uuid, accesspage:true});
        };


        vm.addToFavorites = function (id, name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/addToFavorites.html',
                controller: 'AddToFavoritesController',
                controllerAs: 'addToFavorites',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    sourceid: function () { return id},
                    sourcename: function () { return name},
                    reload : function () { return vm.reload}
                }
            });
        };


        vm.delToFavorites = function(id) {
          swal({
            title: "取消收藏",
            text: "取消",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/ci/favorites/' + vm.treeid + '?ciid=' + id ).success(function(data){
                if(data.stat)
                {
                    vm.reload();
                }
                else
                {
                    toastr.error( "取消收藏失败:" + data.info )
                }
            });
          });
        }

        vm.copyProject = function (id, name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/copyProject.html',
                controller: 'CopyProjectController',
                controllerAs: 'copyProject',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    sourceid: function () { return id},
                    sourcename: function () { return name+ '_copy'},
                    reload : function () { return vm.reload}
                }
            });
        };

        vm.copyProjectToTemplate = function (id, name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/copyProjectToTemplate.html',
                controller: 'CopyProjectToTemplateController',
                controllerAs: 'copyProjectToTemplate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    sourceid: function () { return id},
                    sourcename: function () { return name},
                    reload : function () { return vm.reload}
                }
            });
        };

        vm.flowlineRename = function (id, name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/flowlineRename.html',
                controller: 'FlowlineRenameController',
                controllerAs: 'flowlineRename',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    sourceid: function () { return id},
                    sourcename: function () { return name},
                    reload : function () { return vm.reload}
                }
            });
        };

        vm.createProject = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/create/blank.html',
                controller: 'CreateProjectController',
                controllerAs: 'createProject',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    editconfig : function () { return vm.editconfig},
                    reload : function () { return vm.reload},
                }
            });
        };

        vm.createProjectByTemplate = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/create/bytemplate.html',
                controller: 'CreateProjectByTemplateController',
                controllerAs: 'createProjectByTemplate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload}
                }
            });
        };


        vm.deleteProject = function(id) {
          swal({
            title: "是否要删除该流水线",
            text: "删除后不能恢复",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/job/jobs/' + vm.treeid + '/_ci_' + id +'_/byname' ).success(function(data){
                if( ! data.stat ){ toastr.error("删除作业配置失败:" + date.info)}
                $http.delete( '/api/ci/project/' + vm.treeid+'/'+ id ).success(function(data){
                    if( ! data.stat ){ toastr.error("删除持续构建配置失败:" + date.info)}
                    $http.delete( '/api/jobx/group/' + vm.treeid + '/_ci_test_' + id +'_/byname'  ).success(function(data){
                        if( ! data.stat ){ toastr.error("删除测试分批组失败:" + date.info)}
                        $http.delete( '/api/jobx/group/' + vm.treeid + '/_ci_online_' + id +'_/byname'  ).success(function(data){
                            if( ! data.stat ){ toastr.error("删除线上分批组失败:" + date.info)}
                            vm.reload();
                        });
                    });
                });
            });
          });
        }

        vm.taskInfoTest = {}
        vm.taskInfoOnline = {}

        vm.taskInfoTestRunning = {}
        vm.taskInfoOnlineRunning = {}

        vm.getTaskInfo = function (treeId) {
            $http.get('/api/jobx/task/' + treeId + '?allowslavenull=1&name=_ci_' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        angular.forEach(response.data.data, function (value, key) {

                        var projectid = vm.cprojectid( value.name );
                        var version = vm.cversion( value.variable );
                        var jobtype = vm.cjobtype( value.variable );
                        value.version = version

                        if( value.slave != '_null_' && jobtype == 'test' )
                        {
                            vm.taskInfoTest[projectid] = value
                            if( value.status == 'running' )
                            {
                                vm.taskInfoTestRunning[projectid] = 1
                            }
                        }

                        if( value.slave != '_null_' && jobtype == 'online' )
                        {
                            vm.taskInfoOnline[projectid] = value
                            if( value.status == 'running' )
                            {
                                vm.taskInfoOnlineRunning[projectid] = 1
                            }
                        }

                        });
                    }else {
                    }
                },
                function errorCallback (response){
                });
        };
        vm.getTaskInfo(vm.treeid);

        vm.cprojectid = function(text) {
            var w = text.split("_");
            if(w[1] == 'ci' && w[0] == '' && w[3] == '' )
            {
                return w[2]
            }
            else
            {
                return ''
            }
        }

        vm.cversion = function(text) {
            var w = '';
            var re=/\bversion:.*/;
            if (re.test(text)){
                var reStr = re.exec(text)[0];
                w = reStr.split(" ")[1]
                var xx = /'/;
                if( xx.test(w) )
                {
                    w = w.split("'")[1]
                }
            }
            return w
        }

        vm.cjobtype = function(text) {
            var w = '';
            var re=/\b_jobtype_:.*/;
            if (re.test(text)){
                var reStr = re.exec(text)[0];
                w = reStr.split(" ")[1]
                var xx = /'/;
                if( xx.test(w) )
                {
                    w = w.split("'")[1]
                }
            }
            return w
        }

        vm.deployType = function (uuid){
            uuid = uuid.slice(uuid.length - 1);
            if (64 < uuid.charCodeAt(0) && uuid.charCodeAt(0) < 91) {
                return '回滚'
            } else {
                return '发布'
            }
        };

        vm.describedeployment = function (ticketid,type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describedeployment.html',
                controller: 'KubernetesDescribeDeploymentController',
                controllerAs: 'kubernetesdescribedeployment',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return ticketid},
                }
            });
        };

    }
})();
