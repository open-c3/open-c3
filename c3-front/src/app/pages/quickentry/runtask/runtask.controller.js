(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('RunTaskController', RunTaskController);

    function RunTaskController($state, $uibModal,$http, $scope, ngTableParams,resoureceService, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.jobid = $state.params.jobid;

        var toastr = toastr || $injector.get('toastr');

        $scope.allJobs = [];        // 保存所有项目下的作业
        $scope.jobVar = [];         // 保存作业中需要填写的变量
        $scope.choiceJob = null;    // 已选择的作业数据
        $scope.taskData = {
            'jobname':null,
            'group':null,
            'variable':{},
            'uuid':null,
        };

        vm.handwritten = {};

        vm.getAllJob = function () {
            vm.ciinfo = {}

            $http.get('/api/ci/group/' + vm.treeid).success(function(data){
                if(data.stat)
                {
                    angular.forEach(data.data, function (value, key) {
                        vm.ciinfo['_ci_'+value.id+'_'] = value.name
                        vm.ciinfo['_ci_test_'+value.id+'_'] = value.name + ':测试'
                        vm.ciinfo['_ci_online_'+value.id+'_'] = value.name + ':线上'
                    });

                    $http.get('/api/job/jobs/' + vm.treeid).then(
                        function successCallback(response) {
                            if (response.data.stat){
                                if( vm.jobid )
                                {
                                    angular.forEach(response.data.data, function (value, key) {
                                        if( value.id == vm.jobid )
                                        {
                                            $scope.allJobs = [ value ];
                                            $scope.choiceJob = value
                                        }
                                    });
                                }
                                else
                                {
                                    $scope.allJobs = response.data.data
                                }
                                angular.forEach($scope.allJobs, function (value, key) {
                                    if(vm.ciinfo[value.name])
                                    {
                                        value.alias = '(流水线:' + vm.ciinfo[value.name] +')'
                                    }else{
                                        value.alias = value.name
                                    }
                                });
                            }else {
                                toastr.error( "获取项目机器信息失败："+response.data.info )
                            }
                        },
                        function errorCallback (response ){
                            toastr.error( "获取项目机器信息失败："+response.status )
                        });


                    $http.get('/api/jobx/group/' + vm.treeid).then(
                        function successCallback(response) {
                            if (response.data.stat){
                                $scope.allGroups = response.data.data
                                angular.forEach($scope.allGroups, function (value, key) {
                                    if(vm.ciinfo[value.name])
                                    {
                                        value.alias = '(流水线:' + vm.ciinfo[value.name] +')'
                                    }else{
                                        value.alias = value.name
                                    }
                                });
 
                            }else {
                                toastr.error( "获取分组机器信息失败："+response.data.info )
                            }
                        },
                        function errorCallback (response){
                            toastr.error( "获取分组机器信息失败："+response.status )
                        });
                }
                else
                {
                    toastr.error( "加载流水线名称失败:" + data.info )
                }
            });


        };

        vm._rollbackVersion_ = '';
        vm.deployversion = '';

        vm.iamtask4jobx = 0;
        vm.showjobxgroup = 0;
        vm.varsvalue = {};

        vm.runTask = function(){
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });
            if( vm._rollbackVersion_ != "" )
            {
                varDict._rollbackVersion_ = vm._rollbackVersion_;
            }
            if( vm.deployversion != "" )
            {
                varDict.version = vm.deployversion
            }
            $scope.taskData.variable = varDict;

            if( vm.iamtask4jobx )
            {
                resoureceService.task.createtask(vm.treeid, $scope.taskData, null)
                    .then(function (repo) {
                        if (repo.stat){
                            $state.go('home.history.jobxdetail', {treeid:vm.treeid, taskuuid:repo.uuid, accesspage:true});
                        }
                }).finally(function(){ });
            }
            else
            {
                resoureceService.work.runJob(vm.treeid, {"jobuuid":$scope.choiceJob.uuid, "variable": $scope.taskData.variable})
                    .then(function (repo) {
                        if (repo.stat){
                            $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:repo.uuid});
                        }

                     }, function (repo) { });
            }
        };

        vm.loadover = false;
        $scope.$watch('choiceJob', function () {
            if($scope.choiceJob){
                $scope.taskData.jobname = $scope.choiceJob.name;
                vm._rollbackVersion_ = ''
                vm.deployversion = ''
                vm.iamtask4jobx = 0;
                vm.showjobxgroup = 0;
                $scope.taskData.group = null

                vm.loadover = false;
                $http.get('/api/job/variable/' + vm.treeid + '/' + $scope.choiceJob.uuid + "?empty=0").then(
                    function successCallback(response) {

                        if (response.data.stat){
                            vm.vartemp = [];
                            angular.forEach(response.data.data, function (value, key) {

                                if( value.value == "" )
                                {
                                    if( value.name == "ip" )
                                    {
                                        if( value.describe != "" )
                                        {
                                            vm.groupstr = value.describe.split(":");
                                            
                                            if( vm.groupstr[0] == 'group' )
                                            {
                                                if( value.describe == 'group' )
                                                {
                                                    vm.iamtask4jobx = 1;
                                                    vm.showjobxgroup = 1;
                                                }
                                                else
                                                {
                                                    $scope.taskData.group = vm.groupstr[1];
                                                    vm.iamtask4jobx = 1;
                                                    vm.showjobxgroup = 0;
                                                }
                                            }
                                            else
                                            {
                                                vm.vartemp.push( value )
                                            }
                                        }
                                        else
                                        {
                                            vm.vartemp.push( value )
                                        }
                                    }
                                    else
                                    {
                                        vm.vartemp.push( value )

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
                                    }
                                }
                                else
                                {
                                    if( value.name == "_rollbackVersion_" )
                                    {
                                        vm._rollbackVersion_ = value.value
                                    }
                                    if( value.name == "version" )
                                    {
                                        vm.deployversion = value.value
                                    }
                                }

                            });

                            if (vm.vartemp.length == 0){
                                $scope.jobVar = [];
                                $scope.taskData.variable = {};
                            }else {
                                $scope.jobVar = vm.vartemp;

                            }
                            vm.loadover = true;
                        }else {
                            toastr.error( "获取变量信息失败："+response.data.info )
                        }
                    },
                    function errorCallback (response){
                        toastr.error( "获取变量信息失败："+response.status )
                    });

            }

        }, true);
        vm.getAllJob();
    }
})();

