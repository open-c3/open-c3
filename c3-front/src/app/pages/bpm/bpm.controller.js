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

        $scope.jobVar = [];         // 保存作业中需要填写的变量
        $scope.choiceJob = null;    // 已选择的作业数据
        $scope.taskData = {
            'jobname':null,
            'group':null,
            'variable':{},
            'uuid':null,
        };

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

        vm.jobsloadover = false;


        vm.varsvalue = {};

        vm.runTask = function(){
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });
            $scope.taskData.variable = varDict;
            $scope.taskData.variable['_jobname_'] = $scope.choiceJob.name;

            resoureceService.work.runJobByName(vm.treeid, {"jobname":$scope.choiceJob.name, "bpm_variable": $scope.taskData.variable, "variable": {} })
                .then(function (repo) {
                    if (repo.stat){
                        $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:repo.uuid});
                    }

                 }, function (repo) { });
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
                $scope.taskData.group = null

                vm.loadover = false;
                $http.get('/api/job/bpm/variable/' + $scope.choiceJob.name ).then(
                    function successCallback(response) {

                        if (response.data.stat){
                            vm.vartemp = [];
                            angular.forEach(response.data.data, function (value, key) {
                                if( value.value == "" )
                                {
                                     vm.vartemp.push( value )
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

