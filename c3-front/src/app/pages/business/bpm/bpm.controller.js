(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('BusinessBpmController', BusinessBpmController);

    function BusinessBpmController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, scriptId, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.deleteBpm = function(name){
            swal({
                title: "删除",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete( '/api/job/bpm/manage/conf/' + name  ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'删除失败', text: data.info, type:'error' });
                    }
 
                });
              });
        };

        vm.Reset = function () {
            vm.bpmname = "";
            vm.reload()
        };

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.bpmname){
                get_data.name=vm.bpmname
            }
            $http({
                method:'GET',
                url:'/api/job/bpm/manage/menu',
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.dataTable = new ngTableParams({count:10}, {counts:[],data:response.data.data});
                    }else {
                        swal('获取列表失败', response.data.info, 'error');
                    }
                },
                function errorCallback(response) {
                    swal('获取列表失败', response.status, 'error');
                }
            );

        };

        vm.reload();

    }

})();
