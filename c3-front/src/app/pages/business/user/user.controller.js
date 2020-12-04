(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('UserController', UsersController);

    function UsersController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService) {

        var vm = this;

        vm.treeid = $state.params.treeid;

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.createuser = data.email;
            });
        };

        $('#createstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createStart = result;
            $scope.$apply();
        });

        vm.Reset = function () {
            vm.username = "";
            vm.createuser = "";
            vm.createStart = "";
            vm.createEnd = "";
            vm.reload();
        };

        $('#createend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createEnd= result;
            $scope.$apply();
        });

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.username){
                get_data.name=vm.username
            }
            if(vm.createuser){
                get_data.create_user=vm.createuser
            }
            if(vm.createStart){
                get_data.create_time_start=vm.createStart
            }
            if(vm.createEnd){
                get_data.create_time_end=vm.createEnd
            }

            $http({
                method:'GET',
                url:'/api/job/userlist/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.user_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                    }else {
                        swal({ title:'获取用户列表失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback(response) {
                    swal({ title:'获取用户列表失败', text: response.status, type:'error' });
                }
            );


        };

        vm.createUser = function () {
            $http.post('/api/job/userlist/'+ vm.treeid, {'username': $scope.newUser}).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.reload();
                        $scope.newUser = '';
                    }else {
                        swal({ title:'创建用户失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response ){
                    swal({ title:'创建用户失败', text: response.status, type:'error' });
                }
            );
        };

        vm.delete = function(id){
            swal({
                title: "删除用户",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/job/userlist/' + vm.treeid + '/' + id ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'删除用户失败', text: data.info, type:'error' });
                    }
                });
            });
        };

        vm.reload();
    }

})();
