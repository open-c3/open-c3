(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorNodeController', ConnectorNodeController);

    function ConnectorNodeController($state, $http, $scope, ngTableParams) {
        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.addNode = function () {
            $http.post('/api/connector/default/node/'+ vm.treeid, {'name': $scope.nodename}).success(function(data){
                if (data.stat){
                    swal({ title: '添加成功', type:'success' });
                    vm.reload();
                }else {
                    swal({ title: '添加失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.delete = function(id){
            swal({
                title: "删除资源",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/connector/default/node/' + vm.treeid + '/' + id  ).success(function(data){
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
            $http.get('/api/connector/default/node/' + vm.treeid).success(function(data){
                if (data.stat){
                    vm.nodeTable = new ngTableParams({count:10}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取用户列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

    }
})();
