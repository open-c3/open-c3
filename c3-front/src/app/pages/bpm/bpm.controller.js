(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('BpmController', BpmController);

    function BpmController($state, $uibModal,$http, $scope, ngTableParams,resoureceService, $injector) {

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

        vm.c3subtree = [];
        vm.c3subtreeload     = false;
        vm.c3subtreeloadover = false;


        vm.jobsloadover = true;
        vm.menu = [];
        vm.reload = function () {
            vm.jobsloadover = false;
            $http.get('/api/job/bpm/menu' ).success(function(data){
                vm.jobsloadover = true;
                if (data.stat){
                    vm.menu = data.data;
                }else {
                    swal({ title:'获取应用地址失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

        vm.loadsubtree = function()
        {
             if( vm.c3subtreeload )
             {
                 return;
             }
             vm.c3subtreeload = true;

             $http.get('/api/ci/v2/c3mc/tree/subtreemap/' + vm.treeid).then(
                 function successCallback(response) {
                     if (response.data.stat){
                         vm.c3subtree = response.data.data;
                         vm.c3subtreeloadover = true;
                     }else {
                         toastr.error( "加载子服务树失败："+response.data.info )
                     }
                 },
                 function errorCallback (response){
                     toastr.error( "加载子服务树失败："+response.status )
                });
 
        };


        vm.jobsloadover = false;

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
                resoureceService.work.runJobByName(vm.treeid, {"jobname":$scope.choiceJob.name, "variable": $scope.taskData.variable})
                    .then(function (repo) {
                        if (repo.stat){
                            $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:repo.uuid});
                        }

                     }, function (repo) { });
            }
        };

        vm.choiceServer = function () {
                var openChoice = $uibModal.open({
                templateUrl: 'app/components/machine/choiceMachine.html',
                controller: 'ChoiceController',
                controllerAs: 'choice',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},

                }
            });
            openChoice.result.then(
                function (result) {
                    if (result.length != 0){
                        $scope.choiceShow = true;
                        var machineInfoNew = "";
                        angular.forEach($scope.jobVar, function (value, key) {
                            if( value.name == "ip" )
                            {
                                value.value = result.join(',');
                            }

                        });
 
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
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
                $http.get('/api/job/bpm/variable/' + $scope.choiceJob.name ).then(
                    function successCallback(response) {

                        if (response.data.stat){
                            vm.vartemp = [];
                            angular.forEach(response.data.data, function (value, key) {

                                if( value.value == "" )
                                {
                                    if( value.name == "C3SUBTREE" )
                                    {
                                        vm.loadsubtree();
                                    }

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
                                        if( value.name != "_pip_" )
                                        {
                                            vm.vartemp.push( value )
                                        }
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
    }
})();

