(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('RunTask2CiController', RunTask2CiController);

    function RunTask2CiController($state, $uibModalInstance, $uibModal,$http, $scope, ngTableParams,resoureceService, name, version, groupname, jobtype, showIPstr, jobStep, projectname, $timeout, projectid, noshowrollback, versionlist, $injector ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.version = version

        vm.advancedconfig = 0;
        vm.versionlist = versionlist;

        var toastr = toastr || $injector.get('toastr');

        vm.projectname = projectname
        vm.showIPstr = showIPstr
        vm.jobStep = jobStep
        vm.jobtype = jobtype
        $scope.taskData = {
            'jobname':null,
            'group':groupname,
            'variable':{},
            'uuid':null,
        };
        vm.rollbacknoneeded = false

        vm.varsvalue = {};
        vm.handwritten = {};

        vm.jobinfo;
        vm.loadover = false;
        vm.checkerIsMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                if( ! $scope.taskData.variable.checker )
                {
                    $scope.taskData.variable.checker = data.email;
                }
            });
        };
        vm.getAllJob = function () {
            $http.get('/api/job/jobs/' + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        angular.forEach(response.data.data, function (data, index) {
                            if( data.name == name )
                            {
                                vm.jobinfo = data
                            }
                        });
 
                        if( vm.jobinfo )
                        {
                            $scope.taskData.jobname = vm.jobinfo.name;

                            $http.get('/api/job/variable/' + vm.treeid + '/' + vm.jobinfo.uuid + "?empty=1&env=" + jobtype ).then(
                               function successCallback(response) {
                                   if (response.data.stat){
                               //        if (response.data.data.length == 0){
                               //            $scope.jobVar = [];
                               //            $scope.taskData.variable = { '_jobtype_': jobtype };
                               //        }else {
                                           $scope.jobVar = response.data.data;

                                           if( jobtype == 'test' )
                                           {
                                               $scope.taskData.variable = {version: version, '_jobtype_': jobtype, '_exit_': 1 };
                                           }
                                           else
                                           {
                                               $scope.taskData.variable = {version: version, '_jobtype_': jobtype, '_appname_': $scope.taskData.jobname, '_skipSameVersion_': 0 };
                                           }
                                           angular.forEach(response.data.data, function (value, key) {
                                                if( value.option )
                                                {
                                                   var splitstr = ",";
                                                   if( value.option.search(/;/) >= 0 )
                                                   {
                                                       splitstr = ";"
                                                   }
                                                   var vars = value.option.split(splitstr);
                                                   if( value.option.length > 0 &&  vars.length > 0 )
                                                   {
                                                       vm.varsvalue[ value.name ] = vars;
                                                   }
                                                }
                                                if( value.name == 'checker' )
                                                {
                                                    vm.checkerIsMe();
                                                }
 
                                           });

                                           vm.loadover = true;
                               //        }
                                  }else {
                                      alert("获取作业变量失败："+response.data.info)
                                  }
                              },
                              function errorCallback (response ){ });
                        }else {
                            alert("作业没有进行配置："+response.data.info)
                        }
                    }else {
                        alert("获取作业列表失败："+response.data.info)
                    }
                },
                function errorCallback (response ){
                });
        };




        vm.getAllGroup = function () {
            $http.get('/api/jobx/group/' + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.allGroups = response.data.data
                    }else {
                        // alert("获取分组信息失败："+response.data.info)
                    }
                },
                function errorCallback (response){
                    $scope.dataready = false;
                    $scope.dataerror = "获取分组信息失败";
                });
        };

        vm.runTask = function(){
            if ( vm.rollbacknoneeded )
            {
                delete $scope.taskData.variable._rollbackVersion_;
            }

            if( $scope.taskData.variable.version == '' )
            {
                if( ! vm.describeversioncurrent )
                {
                    vm.describeversioncurrent = "deplpy:" + vm.deployversioncurrent;
                }
                $http.post('/api/ci/version/' + vm.treeid + '/' + projectid + '/record', { version: vm.deployversioncurrent, describe: vm.describeversioncurrent } ).success(function(data){
                    if(data.stat == true) {

                        $scope.taskData.variable.version = vm.deployversioncurrent;
                        resoureceService.task.createtask(vm.treeid, $scope.taskData, null)
                            .then(function (repo) {
                                if (repo.stat){
                                    $state.go('home.history.jobxdetail', {treeid:vm.treeid, taskuuid:repo.uuid, accesspage:true});
                                    vm.cancel()
                                }
                        }).finally(function(){ });

                    } else { toastr.error( "创建新版本失败:" + data.info ); }
                });
                return;
            }

            resoureceService.task.createtask(vm.treeid, $scope.taskData, null)
                .then(function (repo) {
                    if (repo.stat){
                        $state.go('home.history.jobxdetail', {treeid:vm.treeid, taskuuid:repo.uuid, accesspage:true});
                        vm.cancel()
                    }
            }).finally(function(){ });
        };
        vm.getAllJob();
        vm.getAllGroup();
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.setRollbackVersion = function ( version )
        {
            $scope.taskData.variable._rollbackVersion_ = version
        }

        vm.lastversion = {};
        vm.getLastVersion = function () {
            $http.get('/api/jobx/flowline_version/' + projectid ).then(
                function successCallback(response) {
                    if (response.data.stat) {
                        vm.lastversion = response.data.data;
                    }else{
                        toastr.error( "获取作业信息失败：" + response.data.info )
                    };
                });
                function errorCallback(response) {
                    toastr.error( "获取作业信息失败：" + response.status )
                }
        };


        vm.getLastVersion();

        vm.showVersions = function (data) {
            var data_info = JSON.stringify(data);
            angular.forEach(data, function (value, key) {
                var container = '#task' + key;
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

        vm.cleanRollbackVersion = function () {
            if (vm.rollbacknoneeded){
                $scope.taskData.variable._rollbackVersion_ = "";
            }
        };

        vm.noshowrollback = noshowrollback;

        vm.error = {};

        vm.checkinput = function( str, key )
        {
            var regex = /[\u4E00-\u9FA5\uF900-\uFA2D]/;
            if (regex.test(str)) {
                vm.error[key]= '参数存在中文';
            }
            else
            {
                vm.error[key] = '';
            }
        }

    }
})();

