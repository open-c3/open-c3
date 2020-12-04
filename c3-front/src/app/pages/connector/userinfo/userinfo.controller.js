(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorUserinfoController', ConnectorUserinfoController);

    function ConnectorUserinfoController($http, ngTableParams) {
        var vm = this;
        vm.addUser = function (usr, title ) {
            $http.post('/api/connector/default/user/adduser', {'user': usr} ).success(function(data){
                if (data.stat){
                    swal({ title: title + '成功', type:'success' });
                    vm.reload();
                }else {
                    swal({ title: title + '用户失败', text: data.info, type:'error' });
                }
            });
        };

        vm.delete = function(name){
            swal({
                title: "删除用户",
                text: "删除后用户不能再登录",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/connector/default/user/deluser?user=' + name ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'删除用户失败', text: data.info, type:'error' });
                    }
                });
            });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/default/user/userlist').success(function(data){
                if (data.stat){
                    vm.userTable = new ngTableParams({count:10}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取用户列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();
    }
})();
