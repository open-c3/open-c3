(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateGroupController', CreateGroupController);

    function CreateGroupController($uibModal, $uibModalInstance,$http, $scope, resoureceService, treeId, homereload, $injector) {

        var vm = this;
        $scope.choiceShow = false;
        $scope.choiceResult = [];
        $scope.oldselect = '';
        $scope.dataready = true;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        var toastr = toastr || $injector.get('toastr');

        vm.save = function(){
            var plugin = '';
            if (!$scope.selectedType){
                toastr.error( "分组类型必选！" )
                return
            }
            if ($scope.selectedType == "machineName" && $scope.choiceResult.length != 0){
                plugin = 'node';
                var postdata = $scope.choiceResult.join(",");
            }else if ($scope.selectedType == "machineType" && $scope.choiceResult.length != 0){
                plugin = 'type';
                var postdata = $scope.choiceResult.join(",");
            }

            var d = {
                "name":$scope.groupName,
                "plugin":plugin,
                "params":postdata
            };

            resoureceService.group.create(treeId, d, null)
                .then(function () {
                    vm.cancel();
                    homereload();
                })
                .finally(function(){

                });
        };

        vm.getProMachine = function () {
            $http.get('/api/agent/nodeinfo/' + treeId).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.machineData = response.data;
                    }else {
                        toastr.error( "获取项目机器信息失败" + response.data.info )
                    }
                },
                function errorCallback (response ){
                    toastr.error( "获取项目机器信息失败" + response.status )
                });
        };

        vm.delChoice = function (id) {
            if (id >=0){
                $scope.choiceResult.splice(id, 1);
            }
        };

        vm.groupInfo = function () {

            var choiceMachie = $uibModal.open({
                templateUrl: 'app/pages/business/nodegroup/choiceInfo/machineGroup.html',
                controller: 'GroupInfoController',
                controllerAs: 'groupInfo',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    selectedType: function () { return $scope.selectedType},
                    allmachineInfo : function () { return vm.machineData }
                }
            });

            choiceMachie.result.then(
                function (result) {
                    if (result.length != 0){
                        $scope.choiceShow = true;
                        $scope.choiceResult = result;
                        $scope.oldselect = $scope.selectedType;
                    }else {
                        // $scope.selectedType = '';
                        $scope.selectedType = $scope.oldselect;
                    }
                },function (reason) {}
            );
        };


        vm.getProMachine();
    }
})();

