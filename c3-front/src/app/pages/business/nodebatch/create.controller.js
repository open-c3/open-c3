(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateJobGroupController', CreateJobGroupController);

    function CreateJobGroupController($state, $uibModal, $uibModalInstance,$http, $scope, ngTableParams, resoureceService, groupid, ciid, grouptype, reloadhome, $injector) {

        var vm = this;
        $scope.machineType = 'list';
        $scope.choiceServerNum = 1;
        vm.machineList = null;
        vm.machinePercent = null;
        var toastr = toastr || $injector.get('toastr');
        vm.postData = {
            'name':'',
            'note':'',
        };
        vm.ciid = ciid
        if( ciid )
        {
            vm.postData.name = '_ci_' + ciid + '_';
            if( grouptype )
            {
                vm.postData.name = '_ci_' + grouptype + '_' + ciid + '_';
            }
            
            vm.postData.note = 'ci';
        }

        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss(); reloadhome( grouptype )};

        vm.saveGroup = function(){
            vm.postData.group_type = $scope.machineType;
            if ($scope.machineType == 'list'){
                vm.postData['node'] = vm.machineList;
            }else if($scope.machineType == 'percent'){
                vm.postData['percent'] = vm.machinePercent;
            }
            // 编辑分组
            if(groupid){
                resoureceService.group.updategroup([vm.treeid, groupid],vm.postData, null).then(function () {
                    vm.cancel();
                }).finally(function(){

                });
            }
            // 创建分组
            else {
                resoureceService.group.creategroup(vm.treeid,vm.postData, null).then(function () {
                    vm.cancel();
                }).finally(function(){

                });
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
                        machineInfoNew = result.join(',');
                        if (vm.machineList) {
                            vm.machineList = vm.machineList + ";" + machineInfoNew;
                        } else {
                            vm.machineList = machineInfoNew;
                        };
                        $scope.choiceServerNum = vm.machineList.split(';').length + 1;
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
        };
        vm.getMachine = function () {
            $http.get('/api/agent/nodeinfo/' + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.macheinInfoTable = new ngTableParams({count:20}, {counts:[],data:response.data.data});
                    }else {
                        toastr.error( "获取机器信息失败" + response.data.info )
                    }
                },
                function errorCallback (response ){
                    toastr.error( "获取机器信息失败" + response.status )
                });
        };
        vm.getMachine();
        vm.saveGroup = function(){
            vm.postData.group_type = $scope.machineType;
            if ($scope.machineType == 'list'){
                vm.postData['node'] = vm.machineList;
            }else if($scope.machineType == 'percent'){
                vm.postData['percent'] = vm.machinePercent;
            }
            // 编辑分组
            if(groupid){
                resoureceService.group.updategroup([vm.treeid, groupid],vm.postData, null).then(function () {
                    vm.cancel();
                }).finally(function(){

                });
            }
            // 创建分组
            else {
                resoureceService.group.creategroup(vm.treeid,vm.postData, null).then(function () {
                    vm.cancel();
                }).finally(function(){

                });
            }

        };
        if(groupid){
            $http.get('/api/jobx/group/' + vm.treeid+"/"+groupid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.groupData = response.data.data;
                        vm.postData.name = vm.groupData.name;
                        vm.postData.note = vm.groupData.note;
                        $scope.machineType = vm.groupData.group_type;
                        if(vm.groupData.group_type == 'list'){
                            vm.machineList = vm.groupData.node
                        }else if(vm.groupData.group_type == 'percent'){
                            vm.machinePercent = vm.groupData.percent
                        }

                    }else {
                        toastr.error( "获取信息失败" + response.data.info )
                    }
                },
                function errorCallback (response ){
                    toastr.error( "获取信息失败" + response.status )
                });
        }

    }
})();

