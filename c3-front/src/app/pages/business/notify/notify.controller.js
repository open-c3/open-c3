(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AlarmNotifyController', AlarmNotifyController);

    function AlarmNotifyController($state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, $injector) {

        var vm = this;

        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.username = data.email;
            });
        };

        vm.Reset = function () {
            vm.username = "";
            vm.reload();
        };

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.username){
                get_data.name=vm.username
            }

            $http({
                method:'GET',
                url:'/api/job/notify/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.notify_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                    }else {
                        $scope.searchShow = false;
                        toastr.error( "获取列表失败：" + response.data.info );
                    }
                },
                function errorCallback(response) {
                    toastr.error( "获取列表失败：" + response.status );
                }
            );
        };

        vm.createUser = function () {
            vm.newuser = $scope.newUser;
            if (vm.newuser.length > 0){
                $http.post('/api/job/notify/'+ vm.treeid, {'user': vm.newuser}).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            vm.reload();
                            $scope.newUser = '';
                        }else {
                            toastr.error( "添加失败：" + response.data.info );
                        }
                    },
                    function errorCallback (response ){
                        toastr.error( "添加失败：" + response.status );
                    }
                );
            }
        };

        vm.delete = function(id){
            resoureceService.notify.deluser([vm.treeid,id],null, null).finally(function(){
                vm.reload();
            });
        };

        vm.reload();
    }

})();
