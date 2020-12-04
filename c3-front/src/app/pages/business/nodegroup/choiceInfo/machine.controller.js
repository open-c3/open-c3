(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('GroupInfoController', GroupInfoController);

    function GroupInfoController($uibModalInstance,$http, $scope, ngTableParams,resoureceService, treeId, selectedType,allmachineInfo, $injector) {

        var vm = this;
        $scope.selected = [];
        $scope.selectedData = [];
        $scope.allData = [];
        $scope.allType = [];
        $scope.selected_inip = [];
        $scope.selected_exip = [];
        $scope.selected_name = [];
        $scope.radioselected = {};
        $scope.selectedData = [];
        $scope.selectedDataName = [];
        $scope.selectedDataInip = [];
        $scope.selectedDataExip = [];
        $scope.selectType = [];
        $scope.unClick = "true";
        var toastr = toastr || $injector.get('toastr');

        vm.showMachine = function () {
            if (allmachineInfo && allmachineInfo.stat){
                if (selectedType == "machineName") {
                    vm.machine_Table = new ngTableParams({count: 10}, {counts: [], data: allmachineInfo.data.reverse()});
                    $scope.allData = allmachineInfo.data;
                    vm.choiceType = "ip";

                }else if (selectedType =="machineType" ){
                    angular.forEach(allmachineInfo.data, function(data){
                        if ($scope.allType.indexOf(data.type) == -1){
                            $scope.allType.push(data.type);
                        }
                    });
                    vm.type_Table = new ngTableParams({count: 10}, {counts: [], data: $scope.allType});

                    vm.choiceType = "group";
                }
            }else {
                toastr.error( "获取机器信息失败!" )
            }
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

        vm.cancel = function(){
            $uibModalInstance.dismiss()
        };

        vm.ok = function(){
            var ips = [];
            var re_ips = ips.concat($scope.selectedDataName, $scope.selectedDataInip, $scope.selectedDataExip);

            if (selectedType == "machineName"){
                $uibModalInstance.close(
                    re_ips
                );

            }else if (selectedType =="machineType" ){
                $uibModalInstance.close(
                    $scope.selectType
                )
            }

        };
        var changeSelected = function (action, id, data, type) {
            if (action == 'add') {
                if (type == 'name'){
                    $scope.selected_name.push(id);
                    $scope.selectedDataName.push(data);
                }
                if (type == 'inip'){
                    $scope.selected_inip.push(id);
                    $scope.selectedDataInip.push(data);
                }
                if (type == 'exip'){
                    $scope.selected_exip.push(id);
                    $scope.selectedDataExip.push(data);
                }
            }
            if (action == 'remove'){
                if (type == 'name'){
                    $scope.selected_name.splice($scope.selected_name.indexOf(id), 1);
                    $scope.selectedDataName.splice($scope.selectedDataName.indexOf(data), 1)
                }
                if (type == 'inip'){
                    $scope.selected_inip.splice($scope.selected_inip.indexOf(id), 1);
                    $scope.selectedDataInip.splice($scope.selectedDataInip.indexOf(data), 1)
                }
                if (type == 'exip'){
                    $scope.selected_exip.splice($scope.selected_exip.indexOf(id), 1);
                    $scope.selectedDataExip.splice($scope.selectedDataExip.indexOf(data), 1)
                }
            }
        };
        // 机器名称
        $scope.nameUpdateSelection = function ($event, id, data) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            changeSelected(action, id, data, 'name');
        };
        // 内网IP
        $scope.inipUpdateSelection = function ($event, id, data) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            changeSelected(action, id, data, 'inip');
        };
        // 外网IP
        $scope.exipUpdateSelection = function ($event, id, data) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            changeSelected(action, id, data, 'exip');
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
        $scope.isSelected = function (id, type) {
            if (type == 'name'){
                return $scope.selected_name.indexOf(id) >= 0;
            }
            if (type == 'inip'){
                return $scope.selected_inip.indexOf(id) >= 0;
            }
            if (type == 'exip'){
                return $scope.selected_exip.indexOf(id) >= 0;
            }
        };
        $scope.isTypeSelected = function (data) {
            return $scope.selectType.indexOf(data) >= 0;
        };
        $scope.isSelectedAll = function () {
            return $scope.selected.length === $scope.allData.length;
        };
        vm.showMachine();

    }
})();

