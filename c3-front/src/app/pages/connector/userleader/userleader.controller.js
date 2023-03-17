(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorUserleaderController', ConnectorUserleaderController);

    function ConnectorUserleaderController($http, ngTableParams) {
        var vm = this;
        vm.addUser = function (user, leader1, leader2 ) {
            $http.post('/api/connector/default/leader', {'user': user, 'leader1': leader1, 'leader2': leader2 } ).success(function(data){
                if (data.stat){
                    swal({ title: '添加成功', type:'success' });
                    vm.reload();
                }else {
                    swal({ title: '添加失败', text: data.info, type:'error' });
                }
            });
        };

        vm.delete = function(name){
            swal({
                title: "删除",
                text: "删除",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/connector/default/leader?user=' + name ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'删除失败', text: data.info, type:'error' });
                    }
                });
            });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/default/leader').success(function(data){
                if (data.stat){
                    vm.userTable = new ngTableParams({count:10}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();
    }
})();
