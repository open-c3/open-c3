(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('K8sAppTplController', K8sAppTplController);

    /** @ngInject */
    function K8sAppTplController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.mem = {};
        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/job/bpm/k8sapptpl').then(
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

        vm.create = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/k8sapptpl/create.html',
                controller: 'K8sAppTplCreateController',
                controllerAs: 'k8sapptplcreate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
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
                $http.post('/api/job/bpm/k8sapptpl', { "name": name } ).success(function(data){
                    if(data.stat == true) {
                        vm.reload();
                    } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }

                });
            });
        };
    }

})();
