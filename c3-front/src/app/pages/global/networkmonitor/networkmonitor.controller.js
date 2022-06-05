(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('NetworkMonitorController', NetworkMonitorController);

    /** @ngInject */
    function NetworkMonitorController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.mem = {};
        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/networkmonitor').then(
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

        vm.reloadflow = function () {
            vm.flowloadover = false
            $http.get('/api/ci/networkmonitor').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.flowTable   = new ngTableParams({count:20}, {counts:[],data:response.data.data});
                        vm.flowloadover = true
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response ){
                    swal('获取信息失败', response.status, 'error' );
                });
        };

        vm.reloadflow()
    }

})();
