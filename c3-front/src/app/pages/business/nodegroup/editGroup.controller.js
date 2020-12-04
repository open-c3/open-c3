(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('EditGroup', EditGroup);

    function EditGroup($uibModalInstance,$uibModal, $http, $scope, ngTableParams,resoureceService, treeId, groupId, homereload) {

        var vm = this;
        $scope.selected = [];
        $scope.selectedData = [];
        $scope.allData = [];
        $scope.allType = [];
        $scope.selectType = [];
        $scope.unClick = "true";
        var toastr = toastr || $injector.get('toastr');
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.getMachine = function () {
            $http.get('/api/agent/nodeinfo/' + treeId).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.machine_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        vm.machineData = response.data;
                    }else {
                        toastr.error("获取项目下所有机器信息失败："+response.data.info)
                        
                    }
                },
                function errorCallback (response ){
                    toastr.error("获取项目下所有机器信息失败："+response.status)
                });
        };
        vm.getGroupData = function () {
            $http.get('/api/job/nodegroup/' + treeId+"/"+ groupId).then(
                function successCallback(response) {
                    if (response.data.stat){

                        vm.editGroupdata = response.data.data;
                        vm.showEditGroup(vm.editGroupdata)

                    }else {
                        toastr.error("获取指定分组信息失败："+response.data.info)
                    }
                },
                function errorCallback (response ){
                    toastr.error("获取指定分组信息失败："+response.status)
                });
        };
        vm.showEditGroup = function (editData) {
            $scope.groupName = editData.name;
            if (editData.plugin == "node"){
                $scope.oldselect = "machineName";
                $scope.selectedType = "machineName"
            }else if(editData.plugin == "type"){
                $scope.oldselect = "machineType";
                $scope.selectedType = "machineType"
            }
            $scope.editTable = editData.params.split(",");
        };


        vm.choiceInfo = function () {
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
                        $scope.editTable = result;
                        $scope.oldselect = $scope.selectedType;
                    }else {

                        $scope.selectedType = $scope.oldselect;
                    }

                },function (reason) {}
            );
        };

        vm.delChoice = function (id) {
            if (id >=0){
                $scope.editTable.splice(id, 1);
            }
        };


        vm.save = function(){
            var plugin = '';
            if (!$scope.selectedType){
                alert("分组类型必选！");
                return
            }
            if ($scope.selectedType == "machineName" && $scope.editTable.length != 0){
                plugin = 'node';
                var postdata = $scope.editTable.join(",");
            }else if ($scope.selectedType == "machineType" && $scope.editTable.length != 0){
                plugin = 'type';
                var postdata = $scope.editTable.join(",");
            }

            var d = {
                "name":$scope.groupName,
                "plugin":plugin,
                "params":postdata
            };

            resoureceService.group.change([treeId,groupId], d, null)
                .then(function () {

                    vm.cancel();
                    homereload();
                })
                .finally(function(){

                });
        };

        vm.cleanSelected = function () {
            $scope.selected = [];
            var from = $scope.formType;

            if (from == "ip"){
                $scope.allData = vm.machineData;
            }else if(from == "group"){
                $scope.allData = vm.groupData;
            }
        };

        vm.ok = function(){
            if (selectedType == "machineName"){
                $uibModalInstance.close(
                    $scope.selectedData
                )

            }else if (selectedType =="machineType" ){
                $uibModalInstance.close(
                    $scope.selectType
                )
            }

        };


        var updateSelected = function (action, id, data) {
            if (action == 'add' & $scope.selected.indexOf(id) == -1) {
                $scope.selected.push(id);
                $scope.selectedData.push(data.name);
            }
            if (action == 'remove' && $scope.selected.indexOf(id) != -1){
                $scope.selected.splice($scope.selected.indexOf(id), 1);
                $scope.selectedData.splice($scope.selectedData.indexOf(data.name), 1)
            }
        };
        var updateTypeSelected = function (action, data) {
            if (action == 'add' & $scope.selectType.indexOf(data) == -1) {
                $scope.selectType.push(data);
            }
            if (action == 'remove' && $scope.selected.indexOf(data) != -1){
                $scope.selectType.splice($scope.selectType.indexOf(data), 1);
            }
        };
        $scope.updateSelection = function ($event, id, data) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            updateSelected(action, id, data);
        };
        $scope.updateTypeSelection = function ($event, data) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            updateTypeSelected(action, data);
        };
        $scope.selectAll = function ($event) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            for (var i = 0; i < $scope.allData.length; i++) {
                var entity = $scope.allData[i];
                updateSelected(action, entity.id, entity);
            }
        };
        // $scope.getSelectedClass = function (entity) {
        //     return $scope.isSelected(entity.id) ? 'selected' : '';
        // };
        $scope.isSelected = function (id) {
            return $scope.selected.indexOf(id) >= 0;
        };
        $scope.isTypeSelected = function (data) {
            return $scope.selectType.indexOf(data) >= 0;
        };
        $scope.isSelectedAll = function () {
            return $scope.selected.length === $scope.allData.length;
        };
        vm.getMachine();
        vm.getGroupData();

    }
})();

