(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('SendfileController', SendfileController);

    function SendfileController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');
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

            if( vm.filepath )
            {
                $http.get('/api/job/sendfile/list/' + vm.treeid + '?sudo=' + $scope.selectedUser + '&path=' + vm.filepath  ).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            vm.dir_Table = new ngTableParams({count:200}, {counts:[],data:response.data.data});
                            vm.loadover = true
                        }else {
                            toastr.error( "获取目录列表失败："+response.data.info)
                        }
                    },
                    function errorCallback (response ){
                        toastr.error( "获取目录列表失败："+response.status)
                    });
            }
            else
            {
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
            }
        };

        vm.reload();

        vm.openOne = function (name) {
            vm.filepath = name;
            vm.reload();
        };

        vm.intodir = function (name) {
            vm.filepath = vm.filepath + "/" + name;
            vm.reload();
        };

        vm.backdir = function () {
            var temppath = vm.filepath.split("/");
            temppath.pop();
            vm.filepath = temppath.join("/");
            vm.reload();
        };

        vm.reset = function () {
            vm.filepath = '';
            vm.reload();
        };
    }
})();
