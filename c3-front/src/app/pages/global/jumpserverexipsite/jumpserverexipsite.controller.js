(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('JumpserverExipSiteController', JumpserverExipSiteController);

    /** @ngInject */
    function JumpserverExipSiteController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.mem = {};
        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/device/jumpserverexipsite').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.dataTable   = new ngTableParams({count:20}, {counts:[],data:response.data.data});
                        vm.loadover = true
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response ){
                    swal('获取信息失败', response.status, 'error' );
                });
        };

        vm.reload()

        vm.create = function(name){
            swal({
                title: "创建",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post('/api/agent/device/jumpserverexipsite/' + name ).success(function(data){
                    if(data.stat == true) {
                        vm.reload();
                    } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }

                });
            });
        };

        vm.delete = function(name){
            swal({
                title: "删除",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/agent/device/jumpserverexipsite/' + name ).success(function(data){
                    if(data.stat == true) {
                        vm.reload();
                    } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }

                });
            });
        };
    }

})();
