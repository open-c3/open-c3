(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('TerminalCmdController', TerminalCmdController);

    function TerminalCmdController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');
        $scope.selected_inip = [];
        $scope.selected_exip = [];
        $scope.selected_name = [];
        $scope.radioselected = {};
        $scope.selectedData = [];
        $scope.selectedDataName = [];
        $scope.selectedDataInip = [];
        $scope.selectedDataExip = [];
        $scope.choiceShow = false;
        $scope.selectedUser = 'root';

        treeService.sync.then(function(){ 
            vm.nodeStr = treeService.selectname(); 
        });

        if (vm.treeid){
            $http.get('/api/job/userlist/' + vm.treeid).then(

                function successCallback (response) {
                    if (response.data.stat){
                        $scope.allProUsers= response.data.data;
                    }else {
                        toastr.error( "获取执行账户列表失败："+response.data.info)
                    }
                },
                function errorCallback () {
                    toastr.error( "获取执行账户列表失败："+response.status)
                }
            );
        }

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/nodeinfo/' + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.machine_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        vm.loadover = true
                    }else {
                        toastr.error( "获取机器列表失败："+response.data.info)
                    }
                },
                function errorCallback (response ){
                    toastr.error( "获取机器列表失败："+response.status)
                });
        };

        vm.reload();

        var changeSelected = function (action, id, data, type) {
            if (action == 'add') {
                if (type == 'name'){
                    $scope.selectedData.push(data)
                }
                if (type == 'inip'){
                    $scope.selectedData.push(data)
                }
                if (type == 'exip'){
                    $scope.selectedData.push(data)
                }
            }
            if (action == 'remove'){
                if (type == 'name'){
                    $scope.selectedData.splice($scope.selectedData.indexOf(data), 1)
                }
                if (type == 'inip'){
                    $scope.selectedData.splice($scope.selectedData.indexOf(data), 1)
                }
                if (type == 'exip'){
                    $scope.selectedData.splice($scope.selectedData.indexOf(data), 1)
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
        $scope.isSelected = function (addr) {
            return $scope.selectedData.indexOf(addr) >= 0;
        };
        vm.delChoice = function (id) {
            if (id >=0){
                $scope.selectedData.splice(id, 1);
            }
        };

        vm.delAllData = function () {
            $scope.selectedData.splice(0,$scope.selectedData.length);
        };

        $scope.openOneTab = function (name) {
            var terminalAddr = "http://"+window.location.host+"/api/job/cmd/";
            var s = vm.treeid+"?node=" + name + '&bash=1' +'&sudo=' + $scope.selectedUser;
            window.open(terminalAddr+s, '_blank')
        };

        vm.openNewTab = function () {
            if($scope.selectedData.length<=0){
                swal({
                    title:"所选节点为空",
                    type:'error'
                });
            }
            else {
                var terminalAddr = "http://"+window.location.host+"/api/job/cmd/";
                var node_str = $scope.selectedData.join(",");
                var s = vm.treeid+"?node=" + node_str +'&sudo=' + $scope.selectedUser;
                window.open(terminalAddr+s, '_blank')
            }

        };

        vm.openTailLog = function () {
            if($scope.selectedData.length<=0){
                swal({
                    title:"所选节点为空",
                    type:'error'
                });
            }
            else {
                var terminalAddr = "http://"+window.location.host+"/api/job/cmd/";
                var node_str = $scope.selectedData.join(",");
                var s = vm.treeid + "?node=" + node_str +'&sudo=' + $scope.selectedUser + '&tail=1';
                window.open(terminalAddr + s, '_blank');
            }

        };
    }

})();
