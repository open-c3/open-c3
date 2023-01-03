(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('BpmController', BpmController);

    function BpmController($state, $uibModal,$http, $scope, ngTableParams,resoureceService, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.defaulttreeid = '0';
        vm.bpmuuid = $state.params.bpmuuid;
        vm.jobid = $state.params.jobid;

        vm.optionx = {};
        var toastr = toastr || $injector.get('toastr');

        $scope.jobVar = [];         // 保存作业中需要填写的变量
        $scope.choiceJob = null;    // 已选择的作业数据
        $scope.taskData = {
            'jobname':null,
            'group':null,
            'variable':{},
            'uuid':null,
        };

        vm.bpmvar = {};
        vm.loadbpmvar = function () {
            $http.get('/api/job/bpm/var/' + vm.bpmuuid ).success(function(data){
                if (data.stat){
                    vm.bpmvar = data.data;
                    vm.reload();
                }else {
                    swal({ title:'获取表单内容失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.optionxchange = function( stepname )
        {
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });

            $http.post( '/api/job/bpm/optionx', { "bpm_variable": varDict, "stepname": stepname, "jobname":$scope.choiceJob.name } ).success(function(data){
                if (data.stat){
                    vm.optionx[stepname] = data.data
                }else {
                    swal({ title: '获取选项失败', text: data.info, type:'error' });
                }
            });
 
        }

        vm.jobsloadover = true;
        vm.menu = [];
        vm.reload = function () {
            vm.jobsloadover = false;
            $http.get('/api/job/bpm/menu' ).success(function(data){
                vm.jobsloadover = true;
                if (data.stat){
                    vm.menu = data.data;
                    angular.forEach(vm.menu, function (data, index) {
                        if( data.name == vm.bpmvar._jobname_ )
                        {
                            $scope.choiceJob = data
                        }
                    });
                }else {
                    swal({ title:'获取应用地址失败', text: data.info, type:'error' });
                }
            });
        };

        vm.jobsloadover = false;
        if( vm.bpmuuid != "0" )
        {
            vm.loadbpmvar();
        }
        else
        {
            vm.reload();
        }


        vm.varsvalue = {};

        vm.runTask = function(){
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });
            $scope.taskData.variable = varDict;

            resoureceService.work.runJobByName(vm.defaulttreeid, {"jobname":$scope.choiceJob.name, "bpm_variable": $scope.taskData.variable, "variable": {} })
                .then(function (repo) {
                    if (repo.stat){
                        $state.go('home.history.bpmdetail', {treeid:vm.defaulttreeid,taskuuid:repo.uuid});
                    }

                 }, function (repo) { });
        };

        vm.reSave = function(){
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });
            $scope.taskData.variable = varDict;

            $http.post( '/api/job/bpm/var/' + vm.bpmuuid, { "bpm_variable": $scope.taskData.variable } ).success(function(data){
                if (data.stat){
                    swal({ title: '保存成功', type:'success' });
                }else {
                    swal({ title: '保存失败', text: data.info, type:'error' });
                }
            });
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

                vm.optionx = {};
                vm.loadover = false;
                $http.get('/api/job/bpm/variable/' + $scope.choiceJob.name ).then(
                    function successCallback(response) {

                        if (response.data.stat){
                            vm.vartemp = [];
                            angular.forEach(response.data.data, function (value, key) {
                                if( value.value == "" )
                                {
                                    if( vm.bpmvar[value.name] != undefined )
                                    {
                                        value.value = vm.bpmvar[value.name] 
                                    }
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

