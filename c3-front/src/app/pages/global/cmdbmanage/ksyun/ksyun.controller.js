(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CmdbManageKsyunController', CmdbManageKsyunController);

    /** @ngInject */
    function CmdbManageKsyunController( $state, $http, $scope, $uibModal, ngTableParams, $uibModalInstance ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/cmdbmanage/account/ksyun').then(
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

        vm.create = function (id) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/ksyun/create.html',
                controller: 'CmdbManageKsyunCreateController',
                controllerAs: 'cmdbmanageksyuncreate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    id: function () { return id}
                }
            });
        };

        vm.delete = function(id){
            swal({
                title: "删除",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete('/api/agent/cmdbmanage/account/ksyun/' + id ).success(function(data){
                    if(data.stat == true) {
                        vm.reload();
                    } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }

                });
            });
        };
    }

})();
