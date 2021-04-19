(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CiController', CiController);

    function CiController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, genericService, $injector, $timeout ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.projectid = $state.params.projectid;
        vm.seftime = genericService.seftime
        var toastr = toastr || $injector.get('toastr');

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });
        $scope.panelcolor = { "success": "green", "fail": "red", "refuse": "orange", "running": "#98b2bc", "decision": "#aaa", "ignore": "#aaa" }

        vm.showEditLog = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/detail/log.html',
                controller: 'CiCtrlLogController',
                controllerAs: 'cictrlLog',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    getGroup: function () {return vm.getGroupInfo},
                    groupid: function () {},
                }
            });
        };

        vm.showTagFind = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/detail/findtag.html',
                controller: 'FindTagController',
                controllerAs: 'findtag',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    projectid: function () {},
                }
            });
        };

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/ci/version/' + vm.treeid + '/' + vm.projectid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeRegionTable = new ngTableParams({count:20}, {counts:[],data:data.data});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载版本失败:" + data.info )
                }
            });
        };

        vm.stop = function(){
            $http.put('api/ci/version/' + vm.treeid + '/' + vm.projectid + '/stop_project').success(function(data){
                if (data.stat == true) {
                    swal({ title: "停止成功!", type:'success' });
                    vm.reload();
                } else {
                    swal({title: "停止失败！", text: data.info, type: 'error'});
                }
            });
        };

        vm.reload();

        vm.reloadprojectinfo = function(){
            $http.get('/api/ci/project/' + vm.treeid + '/' + vm.projectid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.project = data.data;
                } else {
                    toastr.error( "加载项目信息失败:" + data.info )
                }
            });
        };

        vm.reloadprojectinfo();

        vm.showlog = function(versionuuid,slave){
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/showlog.html',
                controller: 'CiShowLogController',
                controllerAs: 'showlog', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    reloadhome: function () { return vm.reload },
                    versionuuid: function () { return versionuuid },
                    slave: function () { return slave }
                }
            });
        };

        vm.build = function( uuid ){
          swal({
            title: "确定构建",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.put('/api/ci/version/' + vm.treeid + '/' + vm.projectid + '/' + uuid + '/build' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.reload();
                } else { 
                    toastr.error( "提交失败:" + data.info )
                }
            })

          })
        };

         vm.killbuild = function( uuid, slave ){
          swal({
            title: "确定停止",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.put('/api/ci/slave/' + slave + '/killbuild/' + uuid  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.reload();
                } else { 
                    toastr.error( "停止操作失败:" + data.info )
                }
            })

          })
        };

        vm.isRollbackTask = function (uuid){
            uuid = uuid.slice(uuid.length - 1);
            if (64 < uuid.charCodeAt(0) && uuid.charCodeAt(0) < 91) {
                return 1
            } else {
                return 0
            }
        };

        vm.taskInfoTest = {}
        vm.taskInfoOnline = {}
        vm.taskInfoRollback = {}

        vm.getTaskInfo = function (treeId) {
            $http.get('/api/jobx/task/' + treeId + '?allowslavenull=1&name=_ci_' + vm.projectid + '_' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        angular.forEach(response.data.data, function (value, key) {

                        var version = vm.cversion( value.variable );
                        var rollbackversion = vm.crollbackversion( value.variable );
                        var jobtype = vm.cjobtype( value.variable );

                        value.version = version
                        value.rollbackversion = rollbackversion

                        if( jobtype == 'test' )
                        {
                            if( ! vm.taskInfoTest[version] )
                            {
                                vm.taskInfoTest[version] = []
                            }
                            vm.taskInfoTest[version].push(value)
                        }

                        if( jobtype == 'online' )
                        {
                            var isRollbackTask = vm.isRollbackTask( value.uuid)
                            if( isRollbackTask )
                            {
                                var str = value.uuid
                                var strrep = str.length - 1
                                str = str.replace(str[strrep],str[strrep].toLowerCase());
                                value.uuid = str
                                vm.taskInfoRollback[value.uuid] = value
                            }
                            else
                            {
                                if( ! vm.taskInfoOnline[version] )
                                {
                                    vm.taskInfoOnline[version] = []
                                }
                                vm.taskInfoOnline[version].push(value)
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

        vm.cversion = function(text) {
            var w = '';
            var re=/version:.*/;
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

        vm.crollbackversion = function(text) {
            var w = '';
            var re=/_rollbackVersion_:.*/;
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
            var re=/_jobtype_:.*/;
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


        vm.deployDetail = function(uuid){
            $state.go('home.history.jobxdetail', {treeid:vm.treeid, taskuuid:uuid, accesspage:true});
        };

        vm.runJob = function(version, jobtype ) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/runTask2Ci.html',
                controller: 'RunTask2CiController',
                controllerAs: 'runtask2ci', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid },
                    version: function () { return version },
                    jobtype: function () { return jobtype },
                    name: function () { return '_ci_' + vm.projectid + '_' },
                    groupname: function () { return '_ci_' + jobtype + '_'  + vm.projectid + '_' },
                    showIPstr: function () { return $scope.showIPstr[jobtype] },
                    jobStep: function () { return vm.jobStep },
                    projectname: function () { return vm.project.name },
                    projectid: function () { return vm.projectid },
                }
            });
        }

        vm.editconfig = function () {
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
                    projectid: function () {return vm.projectid},
                    treeid: function () {return vm.treeid},
                    name: function () {return vm.project.name},
                    groupid: function () {},
                }
            });
        };

    $scope.showIPstr = { 'test': [], 'online': [] };
    $scope.showIPstrLen = { 'test': 0, 'online': 0 };
    vm.loadNodeInfo = function(envname)
    {
        $scope.showIPstr[envname] = [];
        $scope.showIPstrLen[envname] = 0;
        $http.get('/api/jobx/group/' + vm.treeid+"/"+'_ci_' + envname + '_' + vm.projectid + '_'+"/node/byname").then(
            function successCallback(response) {
                if (response.data.stat){
                    vm.groupData = response.data.data;
                    angular.forEach(vm.groupData, function (subip, i) {
                        var suball = [];
                        var onelen = subip.length;
                        if (onelen >0){
                            var ss = 0;
                            var group_num = 0;
                            var ipstr = [];
                            angular.forEach(subip, function (ip, n) {
                                if (ss === 8){
                                    suball.push(ipstr.join());
                                    ss = 0;
                                    ipstr = []
                                }
                                ipstr.push(ip);
                                if(onelen === n+1){
                                    suball.push(ipstr.join());
                                }
                                ss +=1;
                                group_num += 1;
                            });
                            var infos = {"num": group_num, "infos": suball};
                            $scope.showIPstr[envname].push(infos);
                        }
                    })
                    $scope.showIPstrLen[envname] = $scope.showIPstr[envname].length
                }else {
                    toastr.error("获取项目机器信息失败："+response.data.info)
                }
           },
           function errorCallback (response ){
               toastr.error("获取项目机器信息失败："+response.status)
       });

    }

    vm.loadNodeInfo('test');
    vm.loadNodeInfo('online');

    vm.jobStep = []
    vm.jobStepLen = 0
    vm.loadJobInfo = function()
    {
        vm.jobStep = []
        vm.jobStepLen = 0
        $http.get('/api/job/jobs/' + vm.treeid+"/byname?name="+'_ci_' + vm.projectid + '_' ).then(
            function successCallback(response) {
                if (response.data.stat){
                    vm.jobData = response.data.data;
                    if( vm.jobData.data )
                    {
                        angular.forEach(vm.jobData.data, function (d) {
                                vm.jobStep.push(d.name);
                        });
                        vm.jobStepLen = vm.jobStep.length
                    }
                }else {
                    toastr.error( "获取作业信息失败" + response.data.info );
                }
           },
           function errorCallback (response ){
                toastr.error( "获取作业信息失败" + response.status );
       });

    }

    vm.loadJobInfo();

    vm.projectvvversioncount = {}
    vm.projectvvversionnode = {}
    vm.projectvv = +{}
    vm.reloadvv = function(){
        $http.get('/api/job/vv/' + vm.treeid + '?name=APP__ci_' + vm.projectid + '__VERSION' ).success(function(data){
            if(data.stat == true) 
            { 
                vm.projectvv = data.data;
                angular.forEach(vm.projectvv, function (d) {
                    if( ! vm.projectvvversioncount[d.value] )
                    {
                        vm.projectvvversioncount[d.value] = 0
                        vm.projectvvversionnode[d.value] = []
                    }
                    vm.projectvvversioncount[d.value] = vm.projectvvversioncount[d.value] + 1
                    vm.projectvvversionnode[d.value].push( d.node )
                });
            } else {
                toastr.error( "加载项目变量失败:" + data.info )
            }
        });
    };

    vm.reloadvv();

    vm.shownum = function(num)
    {
        if( ! num )
        {
            return 0
        }
        return 2
    }






        vm.versionitems = {};
        vm.versions = [];



        vm.getVersion = function () {
            $http.get('/api/job/vv/' + vm.treeid + '/analysis/version').then(
                function successCallback(response) {
                    if (response.data.stat) {
                        vm.allversion = response.data.data;
                        angular.forEach(vm.allversion, function(project){
                            vm.versionitems[project.name] = [];
                            if( project.name == 'APP__ci_' + vm.projectid  + '__VERSION')
                            {
                                vm.versions.push(project.name);
                            }
                            angular.forEach(project.data, function(value, key) {
                                vm.versionitems[project.name].push([key, parseFloat(value)]);
                            });
                        });
                        $timeout(function(){vm.showVersions(vm.versionitems)}, 0);
                    }else{
                        toastr.error( "获取作业信息失败：" + response.data.info )
                    };
                });
                function errorCallback(response) {
                    toastr.error( "获取作业信息失败：" + response.status )
                }
        };


        vm.getVersion();


        vm.showVersions = function (data) {
            var data_info = JSON.stringify(data);
            angular.forEach(data, function (value, key) {
                var container = '#' + key;
                $(container).highcharts({
                    chart: {
                        plotBackgroundColor: null,
                        plotBorderWidth: null,
                        plotShadow: false
                    },
                    title: {
                        text: ''
                    },
                    tooltip: {
                        headerFormat: '{series.name}<br>',
                        pointFormat: '{point.name}: <b>{point.percentage:.1f}%</b>'
                    },
                    plotOptions: {
                        pie: {
                            allowPointSelect: true,
                            cursor: 'pointer',
                            dataLabels: {
                                enabled: true,
                                format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                                style: {
                                    color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                                }
                            }
                        }
                    },
                    series: [{
                        type: 'pie',
                        name: '',
                        data: value
                    }]
                });
            });

        };


    }
})();
