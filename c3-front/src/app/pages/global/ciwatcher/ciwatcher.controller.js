(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CiWatcherController', CiWatcherController);

    /** @ngInject */
    function CiWatcherController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.mem = {};
        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/ci/watcher').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:100}, {counts:[],data:response.data.data});
                        vm.mem = response.data.mem;
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

        vm.versiondetail = function (treeid,flowid) {
            $state.go('home.quickentry.flowlinedetail', {treeid:treeid, projectid: flowid});
        };
    }

})();
