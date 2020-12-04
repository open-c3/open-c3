(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('ChoiceController', ChoiceController);

    function ChoiceController($uibModalInstance,$timeout, $http, $scope, ngTableParams,resoureceService, treeId) {

        var vm = this;
        $scope.dataready = true;
        $scope.selected = [];
        $scope.selected_inip = [];
        $scope.selected_exip = [];
        $scope.selected_name = [];
        $scope.radioselected = {};
        $scope.selectedData = [];
        $scope.selectedDataName = [];
        $scope.selectedDataInip = [];
        $scope.selectedDataExip = [];
        $scope.allData = [];
        $scope.ipVar = {"variable":"$ip"};
        $scope.formType = 'ip';
        $scope.groupHide = false;
        var ss = window.location.href;
        if(ss.split("#")[1].indexOf("/quickentry/terminal") !=-1){
            $scope.groupHide = true;
        }else if(ss.split("#")[1].indexOf("creaetjob") !=-1){
            $scope.variableShow = true;
        }else if(ss.split("#")[1].indexOf("editjob") !=-1){
            $scope.variableShow = true;
        }else if(ss.split("#")[1].indexOf("business") !=-1){
            $scope.variableShow = true;
        }
 
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.getMachine = function () {
            $http.get('/api/agent/nodeinfo/' + treeId).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.machine_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        vm.machineData = response.data.data;
                    }else {
                        $scope.dataready = false;
                        $scope.dataerror = "获取机器信息失败："+response.data.info;
                    }
                },
                function errorCallback (response ){
                    $scope.dataready = false;
                    $scope.dataerror = "获取机器信息失败："+response.data.status;
                });
        };
        vm.getGroup = function () {
            $http.get('/api/job/nodegroup/' + treeId).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.dataready = true;
                        vm.group_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        vm.groupData = response.data.data;
                    }else {
                        $scope.dataready = false;
                        $scope.dataerror = "获取分组信息失败："+response.data.info;
                    }
                },
                function errorCallback (response ){
                    $scope.dataready = false;
                    $scope.dataerror = "获取分组信息失败："+response.status;
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
        // exip:"119.28.85.72"
        // id:44
        // inip:"10.45.100.99"
        // ip:"10.45.100.99,119.28.85.72"
        // name:"geth-blockscan-txyxg1-01"
        // type:"qcloud-cvm"

        vm.add = function(){
            var ips = [];
            var re_ips = ips.concat($scope.selectedDataName, $scope.selectedDataInip, $scope.selectedDataExip);
            if ($scope.formType == "group" && $scope.radioselected.group){
                $scope.selectedData.push($scope.radioselected.group);
                $uibModalInstance.close(
                    $scope.selectedData
                );
            }
            if ($scope.formType == "ip"){
                $uibModalInstance.close(
                    re_ips
                );
            }
            if ($scope.formType == "variable"){
                $uibModalInstance.close(
                    vm.ipVar
                );
            }

        };


        var updateSelected = function (action, id, data) {
            if (action == 'add' & $scope.selected.indexOf(id) == -1) {
                $scope.selected.push(id);
                $scope.selectedData.push(data);
            }
            if (action == 'remove' && $scope.selected.indexOf(id) != -1){
                $scope.selected.splice($scope.selected.indexOf(id), 1);
                $scope.selectedData.splice($scope.selectedData.indexOf(data), 1)
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
        var updateRadioSelected = function (action, id, data) {
            if (action == 'add' & $scope.selected.indexOf(id) == -1) {
                $scope.selected.push(id);
                $scope.selectedData.push(data);
            }
            if (action == 'remove' && $scope.selected.indexOf(id) != -1){
                $scope.selected.splice($scope.selected.indexOf(id), 1);
                $scope.selectedData.splice($scope.selectedData.indexOf(data), 1)
            }
        };
        $scope.updateSelection = function ($event, id, data) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            updateSelected(action, id, data);
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
        $scope.updateRadio = function ($event, id, data) {
            // var checkbox = $event.target;
            // var action = (checkbox.checked ? 'add' : 'remove');
            // updateSelected(action, id, data);
            $scope.radioselected['group'] = data
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
        $scope.isSelectedAll = function () {
            if ($scope.selected.length){
                return $scope.selected.length === $scope.allData.length;
            }

        };
        vm.getMachine();
        vm.getGroup();
        // $scope.$watch("filter.$", function () {
        //     vm.machine_Table.reload();
        // });

    }
})();

