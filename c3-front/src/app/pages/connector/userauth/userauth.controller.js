(function() {
    'use strict';
    angular
        .module('openc3')
        .controller('ConnectorUserauthController', ConnectorUserauthController);

    function ConnectorUserauthController($http, $scope, $state, ngTableParams) {

       var vm = this;
       vm.role   = 1;
       vm.roleut = 1;

       vm.treeid = $state.params.treeid;

       vm.addAuth = function () {
            $http.post( '/api/connector/default/auth/addauth', {'user': $scope.username, level: vm.role} ).success(function(data){
                if (data.stat){
                    swal({ title: '添加权限成功', type:'success' });
                    $scope.username = ''
                    vm.reload();
                }else {
                    swal({ title: '添加权限失败', text: data.info, type:'error' });
                }
            });
        };

        vm.delete = function(name){
            swal({
                title: "删除用户权限",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/connector/default/auth/delauth?user=' + name ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'删除用户权限失败', text: data.info, type:'error' });
                    }
 
                });
              });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/default/auth/userauth').success(function(data){
                if (data.stat){
                    vm.userTable = new ngTableParams({count:10}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取用户权限列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

        vm.reloadut = function () {
            vm.utloadover = false;
            $http.get('/api/connector/default/auth/tree/userauth').success(function(data){
                if (data.stat){
                    vm.utTable = new ngTableParams({count:10}, {counts:[],data:data.data.reverse()});
                    vm.utloadover = true;
                }else {
                    swal({ title:'获取用户权限列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reloadut();

        vm.addut = function () {
            $http.post( '/api/connector/default/auth/tree/addauth', {'user': $scope.usernameut, tree: vm.treeid, level: vm.roleut} ).success(function(data){
                if (data.stat){
                    swal({ title: '添加权限成功', type:'success' });
                    $scope.username = ''
                    vm.reloadut();
                }else {
                    swal({ title: '添加权限失败', text: data.info, type:'error' });
                }
            });
        };

        vm.deleteut = function(id){
            swal({
                title: "删除用户权限",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/connector/default/auth/tree/delauth?id=' + id ).success(function(data){
                    if (data.stat){
                        vm.reloadut();
                    }else {
                        swal({ title:'删除用户权限失败', text: data.info, type:'error' });
                    }
 
                });
              });
        };

    }
})();
